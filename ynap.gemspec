require_relative 'lib/ynap/version'

Gem::Specification.new do |spec|
  spec.name          = "ynap"
  spec.version       = Ynap::VERSION
  spec.authors       = ["Arnaud Joubay"]

  spec.summary       = %q{You Need A Plaid}
  spec.description   = %q{YNAP allows you to automatically import into YNAB the transactions of any bank supported by Plaid.}
  spec.homepage      = "https://github.com/sowenjub/ynap"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sowenjub/ynap"
  spec.metadata["changelog_uri"] = "https://github.com/sowenjub/ynap/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         =  Dir["{bin,config,exe,html,lib}/**/*", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'plaid', '~> 12.0'
  spec.add_dependency 'sinatra', '~> 2.1'
  spec.add_dependency 'ynab', '~> 1.20'

  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'byebug', "~> 11.0"
  spec.add_development_dependency 'pry', "~> 0.13"
  spec.add_development_dependency 'rake', "~> 13.0"
  spec.add_development_dependency 'rspec', "~> 3.9"

  spec.add_runtime_dependency 'thor', "~> 1.0"
end
