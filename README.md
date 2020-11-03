# Welcome to YNAP

YNAP (You Need A Plaid) is the missing link between Plaid and YNAB.

It allows you to automatically import into YNAB the transactions of any bank supported by Plaid.

Once you've configured the gem, you'll be able to import transactions for the terminal with a simple `ynap import`.

This gem provides:
* a **simple CLI** to import transactions and check your accounts privately. All your access tokens stay on your computer and are generated for read-only access.
* a **repackaged plaid web server** to quickly grab your Plaid tokens
* a guide to set up your own regex to get **clean payees names**

💰 If you don't have a YNAB account yet, you can use my [referral code](https://ynab.com/referral/?ref=CI2L8Hoi7bcZmK4V&utm_source=customer_referral), and we'll both get a free month of YNAB.

🐣 Need help? Follow/DM me on [Twitter](https://twitter.com/sowenjub).

☕️ Ejoying his gem? Buy me a Coffee [![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/B0B01FCLB).

## Installation

Here's an overview of the steps you'll go through before your first `ynap import`.

1. Install the gem & prepare the config file
1. Get your YNAB token
2. Setup your banks
3. Get your Plaid tokens & match Plaid ids to YNAB ids
4. (Optional) Configure the regex used to clean Payees Names

### Get the gem & prepare the config file

Install it locally with:

    $ gem install ynap

Download the `config/ynap.yml.example` example file from the repo and save it somewhere safe on your computer. Rename it to `ynap.yml`.

It looks like this, and we'll complete it in the next steps.

```yml
:plaid:
  :client_id: 1234567890a
  :secret: 1234567890a
  :env: development
  :country_codes: FR
  :redirect_uri: https://{subdomain}.ngrok.io/oauth-response.html
  :web_port: 8000
:ynab:
  :token: your-token
  :budget_id: your-id-in-ynab-url
:regex:
  - ^(?:PRLV|VIR|E-VIR)(?:\sSEPA)?\s(?<name>[^,]*)(?:,.*)?$
  - ^CARTE \d{1,2}\/\d{1,2}\/\d{1,2}\s(?<name>[\w\s]*)(?:\sCB\*\d*)?$
  - ^CB\s\d*\s(?<name>.{11}).*$
:banks:
  - :id: bansky
    :name: Bansky
    :plaid_access_token: access-development-123456789
    :accounts:
      - :plaid_id: account-plaid-id
        :ynab_id: account-ynab-id
        :start_date: "2020-10-23"
  - :id: piggy
    :name: Piggy Bank
    :plaid_access_token: access-development-123456789
    :accounts:
      - :plaid_id: account-plaid-id
        :ynab_id: account-ynab-id

```

### Get your YNAB token

We're going to complete the `:ynab:` parts of the config file:
* Create a new Personal Access Tokens in the [Developer Settings](https://app.youneedabudget.com/settings/developer) (a subsection of your [account settings](https://app.youneedabudget.com/settings))
* Paste the Personal Access Token into your `ynap.yml` file

### Setup your banks

We're going to finish completing the `:ynab:` part of the config file first:
* Go back to the main YNAB interface, click on Budget. The URL should look something like `https://app.youneedabudget.com/{budget_id}/budget/{year-month}`
* Copy the `budget_id` from the URL and paste it in `ynap.yml` under `:ynab:`

Now, for each bank, under `:banks:`, add a new block with this format:

```yaml
- :id: bansky
  :name: Bansky
  :plaid_access_token:
  :accounts:
    - :plaid_id: see-below
      :ynab_id: account-id-for-first-account
      :start_date: "2020-10-23"
    - :plaid_id: see-below
      :ynab_id: account-id-for-second-account
```

* `id` a short string / handle of your choice to easily load a bank (with `Bank.find('bansky')`) or import transactions `ynap import -b bansky`
* `name` used to print infos, such as balances
* `plaid_access_token` the access token for that bank. More details in the Plaid section
* `accounts` is a list of plaid/ynab identifiers used to build the YNAB transactions and save them in the proper account.
  * `start_date` is optional and useful if you already have transactions in YNAB for that account. It indicates the date from which to import transactions. The format is YYYY-MM-DD (year-month-date). If you don't want to bother with this, the script only imports the last 30 days so you can also simply let it import everything & cleanup duplicates (only needed the first time you run the import).

`id` and `name` are up to you, the only thing you have to work for is the `ynab_id` of each account.
To get them, open [YNAB](https://app.youneedabudget.com/) and click on the accounts. The URL will look like this: `https://app.youneedabudget.com/{budget_id}/accounts/{account_id}`.
Take the `account_id` and paste it as the `:ynab_id:` value.


### Get your Plaid tokens & match Plaid ids to YNAB ids

The following steps will get a local server running that will allow you to retrieve one access token per bank account.
This is something you only need to do once.

**Launch ngrok**

The Plaid development environment requires https and a callback URI, so we'll use [ngrok](https://ngrok.com/download) for that.

* Launch ngrok on the same port you specified in `ynap.yml` (8000 by default): `ngrok http 8000`
* Get the URL which should look like this: `https://{randomsubdomain}.ngrok.io`.
* Go back to `ynap.yml` and complete the `redirect_uri` using that URL. It should look like this `https://{randomsubdomain}.ngrok.io/oauth-response.html` (with oauth-response.html)
* On Plaid.com, go to [Team Settings > API](https://dashboard.plaid.com/team/api) > Allowed redirect URIs > Configure and paste that same URI (with oauth-response.html) again.
* Visit https://{randomsubdomain}.ngrok.io

**Launch the plaid web server**

The plaid server is just an easier to use copy of the official [ruby quickstart app](https://github.com/plaid/quickstart/tree/master/ruby). You can find more about the quickstart app here: https://plaid.com/docs/quickstart/.

* Create a [free account](https://dashboard.plaid.com/signup) on Plaid.com
* Copy the **development** [credentials](https://dashboard.plaid.com/overview/development) (client_id/secret) into the `:plaid:` section
* Change the `country_codes` to the one you need. If you have more than one, separate them with a comma, no space (e.g. "FR,GB")
* Assuming your file is accessible in the current folder as `ynap.yml`, start the server:

``` bash
ynap plaid
# or to indicate the path
ynap plaid -c path/to/ynap.yml
```
* Visit `https://{randomsubdomain}.ngrok.io` and you should see a "Connect with Plaid" button.
* Click that "Connect with Plaid" button and follow the steps
* Once you're done, check your console and you should see something like that near the end:
```bash
{
  "access_token": "access-development-random-string",
  "item_id": "otherRandomString",
  "request_id": "moreRandomString"
}
```
* Paste the `access_token` in front of `:plaid_access_token:` in your `config.yml` file, and `item_id` as the `plaid_id` for your account (Most API requests interact with an Item, which is a Plaid term for a login at a financial institution)

**What if you have more than one account at this bank?**

I'm not sure, because I don't have such a situation.
But, having set the access token and the item_id for one account, you can try to call `be bin/ynap plaid_ids boursorama` and see if that gives you all plaid_ids.
It should, but I can't be sure.

### Configure the regex used to clean Payees Names

Part of the magic of YNAB is that they clean bank transaction labels to extract Payees Names.

This means that we have to come up with our own regex expressions to parse the transaction labels.

Here's how to do it:

1. Find the labels that need some cleaning
   * `ynap payees` will output the payees' names. If you spot one that could be better, than call:
   * `ynap payees -m` it does the same but will output the full memo next to the name so that get the raw memo to test your regex against

2. **Write your regex**
   * To play with regexes, I usually use https://rubular.com or https://regexr.com
   * But you can also play with the console:
     * `ynap console`
     * `> PayeeParser.new(/yourregex/).cleaned_name("YOUR TEST LABEL")`
   * Hint: make sure it starts with `^` and end with `$`

3. **Add the regex to your config file**
   * List your regex in the config file in the `:regex:` section

Consider sharing that regex with others by doing a PR or mentioning it in an issue.

### 🎉 Celebrate

You're all set!

![](https://media.giphy.com/media/KYElw07kzDspaBOwf9/source.gif)

## Usage

### My routine

* `ynap payees` to check the payees' names before import and adjust the regex expressions if needed
* `ynap import` to import transactions
* `ynap balances` from time to time, just to check that the Plaid an YNAB balances match
* `ynap diff bank_handle` if the balances don't match, it can be because there are pending transactions (Plaid will have an up-to-date balance but won't have access to the transactions leading to that balance yet). In that case, I just make sure the latests transactions are a match by comparing the last 10 transactions on both sides (or the last n - up to 60 - transactions with `--limit n` or `-l n`)

### All commands

You can get a list of commands by running
```bash
ynap
```

Most commands accept:
*  `-c path/to/config/file.yml` to point to the config file
*  `-b bank_id` to limit the command to the given bank (the `bank_id` is the `id` you set in your config file), except `transactions` which takes it as a required argument

### Good to know

Don't get a headache: don't reconcile your balances in the evenings.

At the time, Plaid will have real-time info about your account balances but might not have the latest transactions.
So you will wonder why the YNAB balance after import doesn't match the Plaid balance.

To find the missing transactions, visit your bank website or app.

### Playing with the console

If you launch the console `ynap console`, look into the bank and account models to see what you can do.

Here are some of the things you'll have acccess to:

``` bash
bank = Bank.find 'bansky'
bank.plaid_transactions
bank.ynab_transactions
bank.payees

account = bank.accounts.first
account.description # prints the balances, Plaid v. YNAB ex: "Bansky: 1234.56 P✅Y 1234.56 EUR"
account.plaid_account
account.ynab_account
```

## Known issues / Roadmap

* **Pending transactions** are not properly supported. I'm not sure it's an issue in Europe, but I'll improve that just in case
* **Simulation** I plan to add a way to simulate the import instead of committing it right away.

## Checking what the code does by yourself

The server that allows you to fetch Plaid tokens is a copy/paste from [Plaid Quickstart](https://github.com/plaid/quickstart), with a modification to load the configuration from your `ynap.yml` config file. You can find it in `bin/plaid`. It uses the html and public folders to render the pages.

The rest is in the lib folder and consists of only a couple of files.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sowenjub/ynap.

1. Fork it ( https://github.com/sowenjub/ynap/fork )
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Run the test suite (`bundle exec rake`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request

To experiment with that code, run `bin/console` for an interactive prompt.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
