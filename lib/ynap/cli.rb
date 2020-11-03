require "thor"
require "ynap"

module Ynap
  class CLI < Thor
    DEFAULT_CONFIG_PATH = 'ynap.yml'

    class_option :verbose, :type => :boolean, :aliases => "-v"

    #
    # System commands
    #

    desc "console", "Start a YNAP console"
    def console
      system("ruby #{File.expand_path File.dirname(__FILE__)}/../../bin/console")
    end

    desc "plaid", "Start the Plaid web server, used during setup to retrieve access tokens"
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    def plaid
      system("ruby #{File.expand_path File.dirname(__FILE__)}/../../bin/plaid #{options.config}")
    end

    #
    # Queries
    #

    desc "plaid_ids [BANK_KEY]", "Print Plaid accounts details for setup"
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    def plaid_ids(bank_id)
      load_config options.config
      puts Bank.find(bank_id).all_plaid_ids
    end

    desc "balances", "Print balances from Plaid"
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    method_option :bank, type: :string, aliases: '-b'
    def balances
      load_config options.config
      if options.bank.nil?
        puts Bank.accounts_descriptions
      else
        puts Bank.find(options.bank).accounts_descriptions
      end
    end

    desc "diff [BANK_KEY]", "Print the latest transactions for YNAB and Plaid for comparison."
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    method_option :limit, type: :numeric, aliases: '-l', default: 10
    def diff(bank_id)
      load_config options.config
      bank = Bank.find(bank_id)
      puts "**************\n* Last #{options.limit} transactions for each account @ #{bank.name}\n**************"
      bank.accounts.each do |account|
        puts "\nAccount: #{account.description}\n"
        puts "\nPlaid\n-------"
        puts account.plaid_transactions.first(options.limit).map(&:description).join("\n")
        puts "\nYNAB\n-------"
        puts account.ynab_transactions.first(options.limit).map(&:description).join("\n")
        puts "\n*******"
      end
    end

    desc "import", "Import available transactions from Plaid to YNAB"
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    method_option :bank, type: :string, aliases: '-b'
    method_option :reconcile, type: :boolean, aliases: '-r', default: true, desc: "Fetches balances after import (slower)"
    def import
      load_config options.config
      puts "* Fetching transactions and preparing import\n"
      if options.bank.nil?
        Bank.all.each(&:import)
      else
        Bank.find(options.bank).import
      end
      if options.reconcile
        puts "\n* Fetching balances\n"
        balances
      end
    end

    desc "payees", "List Payees Names for available transactions"
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    method_option :bank, type: :string, aliases: '-b'
    method_option :memos, type: :boolean, aliases: '-m', default: false
    def payees
      load_config options.config
      if options.bank.nil?
        puts Bank.payees(with_memos: options.memos).join("\n")
      else

        puts Bank.find(options.bank).send(options.memos ? :payees_memos : :payees).join("\n")
      end
    end

    desc "transactions [BANK_KEY]", "Print transactions"
    method_option :config, type: :string, aliases: '-c', default: DEFAULT_CONFIG_PATH
    method_option :side, type: :string, aliases: '-s', default: 'plaid'
    def transactions(bank_id)
      load_config options.config
      bank = Bank.find bank_id
      scope = options.side == 'ynab' ? :ynab_transactions : :plaid_transactions
      puts bank.send(scope).map(&:description).join("\n")
    end

    no_commands{
      def load_config(path)
        Ynap.config = path unless path.nil?
      end
    }
  end
end