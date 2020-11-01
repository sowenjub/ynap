class PayeeParser
  attr_reader :regex

  def initialize(regex = nil)
    @regex = regex || Ynap.regexp
  end

  def cleaned_name(label)
    matched = label.match(@regex)
    matched.nil? ? label : matched[:name].strip
  end
end
