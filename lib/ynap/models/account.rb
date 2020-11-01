require 'date'
require 'ynap/models/bridge_record.rb'

class Account < BridgeRecord
  TRANSACTIONS_HORIZON = 30

  attr_reader :plaid_id, :start_date, :ynab_id

  def initialize(plaid_id:, plaid_access_token:, ynab_id:, start_date: nil)
    super(plaid_access_token)
    @plaid_id     = plaid_id
    @ynab_id      = ynab_id
    @start_date   = Date.parse(start_date) unless start_date.nil?
    @to_date = Date.today
    @from_date = @start_date || (@to_date - TRANSACTIONS_HORIZON)
  end

  def description
    reconciled = reconciled? ? "✅" : "❌"
    "#{ynab_account.name}: #{plaid_balance} P#{reconciled}Y #{ynab_balance.to_plaid} #{plaid_account.balances.iso_currency_code}"
  end

  def balances
    { plaid: plaid_balance, ynab: ynab_balance.to_plaid }
  end

  def reconciled?
    plaid_balance.to_ynab == ynab_balance
  end

  # Plaid

  def plaid_accounts
    @plaid_accounts ||= plaid_client.accounts.balance.get(plaid_access_token).accounts
  end

  def plaid_account
    @plaid_account ||= plaid_accounts.find { |account| account.account_id == plaid_id }
  end

  def plaid_balance
    @plaid_balance ||= plaid_account.balances.available
  end

  def plaid_transactions
    @plaid_transactions ||= plaid_client.transactions.get(plaid_access_token, @from_date, @to_date, account_ids: [plaid_id]).transactions
  end

  # YNAB

  def ynab_account
    @ynab_account ||= ynab_client.accounts.get_account_by_id(Ynap.config.dig(:ynab, :budget_id), ynab_id).data.account
  end

  def ynab_balance
    @ynab_balance ||= ynab_account.balance
  end

  def ynab_transactions
    @ynab_transactions ||= ynab_client.transactions.get_transactions_by_account(Ynap.config.dig(:ynab, :budget_id), ynab_id, since_date: @from_date).data.transactions.reverse
  end
end