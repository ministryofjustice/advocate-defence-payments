source 'https://rubygems.org'
ruby '2.7.3'
gem 'active_model_serializers', '~> 0.10.12'
gem 'amoeba',                 '~> 3.1.0'
gem 'auto_strip_attributes',  '~> 2.6.0'
gem 'aws-sdk-costexplorer',   '~> 1'
gem 'aws-sdk-s3',             '~> 1'
gem 'aws-sdk-sns',            '~> 1'
gem 'aws-sdk-sqs',            '~> 1'
gem 'awesome_print'
gem 'bootsnap', require: false
gem 'cancancan',              '~> 3.2'
gem 'cocoon',                 '~> 1.2.15'
gem 'devise',                 '~> 4.8.0'
gem 'dotenv-rails'
gem 'factory_bot_rails',      '~> 6.2.0'
gem 'faker',                  '~> 2.18.0'
gem 'gov_uk_date_fields',     '~> 3.2'
gem 'govuk_design_system_formbuilder', :github => 'jsugarman/govuk_design_system_formbuilder', :branch => 'debug-multiple-renders'
gem 'govuk_frontend_toolkit', '~> 8.2.0'
gem 'govuk_elements_rails',   '~> 3.1.2'
gem 'govuk_notify_rails',     '~> 2.1.2'
gem 'grape',                  '~> 1.5.3'
gem 'grape-entity',           '~> 0.9.0'
gem 'grape-papertrail',       '~> 0.2.0'
gem 'grape-swagger',          '~> 1.4.0'
gem 'grape-swagger-rails',    '~> 0.3.0'
gem 'haml-rails',             '~> 2.0.1'
gem 'hashdiff',               '>= 1.0.0.beta1', '< 2.0.0'
gem 'hashie-forbidden_attributes', '>= 0.1.1'
gem 'jquery-rails',           '~> 4.4.0'
gem 'json-schema',            '~> 2.8.0'
gem 'nokogiri',               '~> 1.11'
gem 'kaminari',               '>= 1.2.1'
gem 'libreconv',              '~> 0.9.5'
gem 'logstasher',             '2.1.5'
gem 'logstuff',               '0.0.2'
gem 'paper_trail',            '~> 12.0.0'
gem 'pg',                     '~> 1.2.3'
gem 'rails',                  '~> 6.1.3'
gem 'redis',                  '~> 4.3.1'
gem 'rubyzip'
gem 'config',                 '~> 3.1' # this gem provides our Settings.xxx mechanism
gem 'remotipart',             '~> 1.4'
gem 'rest-client',            '~> 2.1' # needed for scheduled smoke testing plus others
gem 'scheduler_daemon',       git: 'https://github.com/jalkoby/scheduler_daemon.git'
gem 'sentry-rails',           '~> 4.5.1'
gem 'sentry-sidekiq',         '~> 4.5.1'
gem 'sprockets-rails',        '~> 3.2.1'
gem 'state_machine',          '~> 1.2.0'
gem 'state_machines-activerecord'
gem 'state_machines-audit_trail'
gem 'tzinfo-data'
gem 'uglifier',                '>= 1.3.0'
gem 'zendesk_api'  ,           '1.30.0'
gem 'sidekiq',                 '~> 6.1'
gem 'sidekiq-failures',        '~> 1.0'
gem 'utf8-cleaner',            '~> 1.0'
gem 'colorize'
gem 'shell-spinner', '~> 1.0', '>= 1.0.4'
gem 'ruby-progressbar'
gem 'geckoboard-ruby'
gem 'posix-spawn', '~> 0.3.15'
gem 'laa-fee-calculator-client', '~> 1.2'
gem 'webpacker', '~> 5.4'
gem 'active_storage_validations'

group :production, :devunicorn do
  gem 'unicorn-rails', '2.2.1'
  gem 'unicorn-worker-killer', '~> 0.4.5'
end

group :development, :devunicorn, :test do
  gem 'annotate'
  gem 'brakeman', :require => false
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'guard-cucumber'
  gem 'guard-livereload', '>= 2.5.2'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-webpacker', '~> 0.2.1'
  gem 'jasmine', '>= 3.5.1'
  gem 'jasmine_selenium_runner', require: false
  gem 'listen', '~> 3.5.1'
  gem 'meta_request'
  gem 'parallel_tests'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'puma'
  gem 'rack-livereload', '~> 0.3.16'
  gem 'rspec-rails', '~> 5.0.1'
  gem 'rspec-collection_matchers'
  gem 'rspec_junit_formatter'
  gem 'net-ssh'
  gem 'net-scp'
  gem 'rubocop', '~> 1.17'
  gem 'rubocop-rspec'
  gem 'rubocop-rails'
  gem 'rubocop-performance'
  gem 'site_prism', '~> 3.7'
end

group :test do
  gem 'axe-core-cucumber', '~> 4.2'
  gem 'capybara-selenium'
  gem 'capybara', '~> 3.35'
  gem 'codeclimate-test-reporter', require: false
  gem 'cucumber-rails', '~> 2.3.0', require: false
  gem 'database_cleaner'
  gem 'i18n-tasks'
  gem 'json_spec'
  gem 'launchy', '~> 2.5.0'
  gem 'rails-controller-testing'
  gem 'rspec-html-matchers', '~> 0.9.4'
  gem 'rspec-mocks'
  gem 'shoulda-matchers', '>= 4.0.0.rc1'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webdrivers', '~> 4.6', require: false
  gem 'webmock'
end
