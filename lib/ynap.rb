require "bigdecimal"
require "date"
require "yaml"
require "ynab"
require "ynap/extensions/plaid/models/transaction"
require "ynap/extensions/ynab/save_transaction"
require "ynap/extensions/ynab/transaction_detail"
require "ynap/extensions/float"
require "ynap/extensions/integer"
require "ynap/models/account"
require "ynap/models/bank"
require "ynap/values/params_converter"
require "ynap/payee_parser"
require "ynap/version"

module Ynap
  class Error < StandardError; end

  def self.config
    @config ||= YAML.load(File.read('ynap.yml'))
  end

  def self.config=(path)
    @config = YAML.load(File.read(path))
  end

  def self.bank_config(id)
    config[:banks].find { |bank_params| bank_params[:id] == id }
  end

  def self.regexp
    @regexp ||= Regexp.union config[:regex].map{ |s| Regexp.new s }
  end

  def self.plaid_client
    @plaid_client ||= Plaid::Client.new config[:plaid].slice(:env, :client_id, :secret)
  end

  def self.ynab_client
    @ynab_client  ||= YNAB::API.new config.dig(:ynab, :token)
  end
end
