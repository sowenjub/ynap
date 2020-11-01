class Float
  def to_ynab
    (BigDecimal(self.to_s) * 1000).to_i
  end
end