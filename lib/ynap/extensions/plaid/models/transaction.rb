require "plaid"

class Plaid::Models::Transaction
  # Includes a negative amount for easier comparison with YNAB transactions
  def description
    [date, "#{(-amount).to_s.rjust(12)} #{iso_currency_code}", name].join(" - ")
  end
end