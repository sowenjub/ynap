class Integer
  def to_plaid
    self.to_f / 1000
  end

  def to_ynab
    self.to_f * 1000
  end
end