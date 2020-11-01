class ParamsConverter
  IMPORT_ID_PREFIX = "GW"
  IMPORT_ID_FIXED_SIZE = IMPORT_ID_PREFIX.length + 10 + 3
  MAX_IMPORT_ID_SIZE = 36

  attr_reader :account, :plaid_transaction

  def initialize(account, plaid_transaction)
    @account           = account
    @plaid_transaction = plaid_transaction
  end

  def amount
    @amount ||= -(BigDecimal(plaid_transaction.amount.to_s) * 100).to_i
  end

  def date
    @date ||= Date.parse(plaid_transaction.date)
  end

  def transaction_id
    @transaction_id ||= plaid_transaction.pending_transaction_id || plaid_transaction.transaction_id
  end

  def transaction_id_length
    @transaction_id_length ||= MAX_IMPORT_ID_SIZE - IMPORT_ID_FIXED_SIZE - amount.to_s.size
  end

  def sliced_transaction_id
    @sliced_transaction_id ||= transaction_id[0, transaction_id_length]
  end

  def import_id
    [IMPORT_ID_PREFIX, amount, date, sliced_transaction_id].join(":")
  end

  def payee_name
    @payee_name ||= plaid_transaction.merchant_name || PayeeParser.new.cleaned_name(plaid_transaction.name)[0, 50]
  end

  def to_params
    {
      account_id: account.ynab_id,
      amount: amount * 10,
      cleared: 'cleared',
      date: date,
      import_id: import_id,
      memo: plaid_transaction.name,
      payee_name: payee_name
    }
  end
end