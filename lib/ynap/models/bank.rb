require 'plaid'
require 'yaml'
require 'ynap/extensions/float.rb'
require 'ynap/models/account.rb'
require 'ynap/models/bridge_record.rb'

class Bank < BridgeRecord
  attr_reader :id, :name, :plaid_access_token, :accounts, :result
  attr_accessor :transactions_horizon

  def initialize(id:, name:, plaid_access_token:, accounts: [])
    super(plaid_access_token)
    @id                   = id
    @name                 = name
    @plaid_access_token   = plaid_access_token
    @accounts             = accounts.map { |params| Account.new params.merge(plaid_access_token: plaid_access_token) }
    @transactions_horizon = Account::TRANSACTIONS_HORIZON
  end

  def self.find(id)
    new Ynap.bank_config(id)
  end

  def self.all
    Ynap.config[:banks].map do |params|
      new params
    end
  end

  def self.accounts_descriptions
    all.map(&:accounts_descriptions).flatten.join("\n")
  end

  def self.payees(with_memos: false)
    with_memos ? payees_memos : all.map(&:payees).flatten.uniq
  end

  def self.payees_memos
    all.map(&:payees_memos).flatten.uniq
  end

  #
  # Plaidist
  #

  # Accounts

  def all_plaid_accounts
    @all_plaid_accounts ||= plaid_client.accounts.get(plaid_access_token).accounts
  end

  def all_plaid_ids
    all_plaid_accounts.map { |account| { name: account.name, official_name: account.official_name, plaid_id: account.account_id } }
  end

  def accounts_descriptions
    accounts.map(&:description)
  end

  def account(plaid_id:)
    accounts.find { |account| account.plaid_id == plaid_id }
  end

  # Transactions

  def fetch_plaid_transactions(from_date: nil, to_date: Date.today)
    start_date = from_date || (to_date - @transactions_horizon)
    plaid_client.transactions.get(plaid_access_token, start_date, to_date).transactions
  end

  def plaid_transactions
    @plaid_transactions ||= fetch_plaid_transactions(from_date: nil, to_date: Date.today)
  end

  # Since we fetch all plaid transactions at once and accounts have various
  # started_date, we need to filter line by line
  def importable_plaid_transactions
    @importable_plaid_transactions ||= plaid_transactions.filter do |transaction|
      account = account(plaid_id: transaction.account_id)
      account.start_date.nil? || Date.parse(transaction.date) >= account.start_date
    end
  end

  def refresh_plaid_transactions!
    plaid_client.transactions.refresh(plaid_access_token)
  end

  #
  # YNABist
  #

  def ynab_transactions
    @ynab_transactions ||= importable_plaid_transactions.map do |plaid_transaction|
      account = account(plaid_id: plaid_transaction.account_id)
      converter = ParamsConverter.new account, plaid_transaction
      YNAB::SaveTransaction.new(converter.to_params)
    end
  end

  def wrapped_ynab_transactions
    YNAB::SaveTransactionsWrapper.new(transactions: ynab_transactions)
  end

  #
  # Transactions Queries
  #

  def transactions_for(ynab_id)
    ynab_transactions.select { |transaction| transaction.account_id == ynab_id }
  end

  def transactions_total(account)
    transactions_for(account.ynab_id).sum(&:amount)
  end

  def payees
    ynab_transactions.map(&:payee_name).uniq.sort
  end

  def payees_memos
    ynab_transactions.map { |t| [t.payee_name, t.memo].join(" <~> ") }.uniq.sort
  end

  #
  # Balances
  #

  def reconciliate_account(account)
    account.ynab_balance + transactions_total(account) == account.plaid_balance.to_ynab
  end

  def reconciled?
    @bank.accounts.inject(true) { |reconciled, account| reconciled && reconciliate_account(account) }
  end

  #
  # Import
  #

  def import
    @result = ynab_client.transactions.create_transactions(Ynap.config.dig(:ynab, :budget_id), wrapped_ynab_transactions).tap do |result|
      puts "#{name} - New: #{result.data.transaction_ids.size}, Known: #{result.data.duplicate_import_ids.size}\n"
    end
  end
end