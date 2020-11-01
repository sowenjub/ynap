require "ynab"

class YNAB::TransactionDetail
  # Includes a decimal amount for easier comparison with Plaid transactions
  def description
    [date, amount.to_plaid.to_s.rjust(12), payee_name, memo].join(" - ")
  end
end