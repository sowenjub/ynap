class BridgeRecord
  attr_accessor :plaid_client, :plaid_access_token, :ynab_client

  def initialize(plaid_access_token)
    @plaid_access_token = plaid_access_token
    @plaid_client = Plaid::Client.new Ynap.config[:plaid].slice(:env, :client_id, :secret)
    @ynab_client  = YNAB::API.new Ynap.config.dig(:ynab, :token)
  end
end