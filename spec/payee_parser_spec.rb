# Test default regex
RSpec.describe PayeeParser do
  before(:each) do
    Ynap.config == "../config/ynap.yml.example"
    @parser = PayeeParser.new
  end

  it "cleans wire transfers" do
    [
      "VIR PAYEE NAME",
      "VIR PAYEE NAME, transaction notes",
      "VIR SEPA PAYEE NAME",
      "VIR SEPA PAYEE NAME, transaction notes",
      "PRLV PAYEE NAME",
      "PRLV PAYEE NAME, transaction notes",
      "PRLV SEPA PAYEE NAME",
      "PRLV SEPA PAYEE NAME, transaction notes",
    ].each do |label|
      expect(@parser.cleaned_name(label)).to eq "PAYEE NAME"
    end
  end

  it "cleans credit cards with date" do
    [
      "CARTE 16/10/20 PAYEE NAME CB*123",
    ].each do |label|
      expect(@parser.cleaned_name(label)).to eq "PAYEE NAME"
    end
  end

  it "cleans credit cards with 11 string characters" do
    [
      "CB 123123 PAYEE NAME 11CITY LE 1111",
    ].each do |label|
      expect(@parser.cleaned_name(label)).to eq "PAYEE NAME"
    end
  end
end
