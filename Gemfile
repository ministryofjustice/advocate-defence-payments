source 'https://rubygems.org'
ruby '2.6.5'
gem 'active_model_serializers', '~> 0.10.10'
gem 'amoeba',                 '~> 3.1.0'
gem 'auto_strip_attributes',  '~> 2.5.0'
gem 'autoprefixer-rails',     '~> 9.7'
gem 'aws-sdk',                '~> 3'
gem 'awesome_print'
gem 'cancancan',              '~> 3.0'
gem 'cocoon',                 '~> 1.2.13'
gem 'devise',                 '~> 4.7.1'
gem 'dry-monads',             '~> 1.3.5'
gem 'dropzonejs-rails',       '~> 0.8.2'
gem 'factory_bot_rails',      '~> 5.1.1'
gem 'faker',                  '~> 2.10.0'
gem 'googlemaps-services',    '~> 1.5.0'
gem 'gov_uk_date_fields',     '~> 3.0.0'
gem 'govuk_template',         '0.26.0'
gem 'govuk_frontend_toolkit', '~> 8.2.0'
gem 'govuk_elements_rails',   '~> 3.1.2'
gem 'govuk_notify_rails',     '~> 2.1.1'
gem 'grape',                  '~> 1.3.0'
gem 'grape-entity',           '~> 0.7.1'
gem 'grape-papertrail',       '~> 0.2.0'
gem 'grape-swagger',          '~> 0.33.0'
gem 'grape-swagger-rails',    '~> 0.3.0'
gem 'haml-rails',             '~> 2.0.1'
gem 'hashdiff',               '>= 1.0.0.beta1', '< 2.0.0'
gem 'hashie-forbidden_attributes', '>= 0.1.1'
gem 'jquery-rails',           '~> 4.3.5'
gem 'json-schema',            '~> 2.8.0'
gem 'nokogiri',               '~> 1.10'
gem 'kaminari',               '~> 0.17.0'
gem 'libreconv',              '~> 0.9.5'
gem 'logstasher',             '0.6.2'
gem 'logstuff',               '0.0.2'
gem 'paperclip',              '~> 6.1.0'
gem 'paper_trail',            '~> 10.3.1'
gem 'pg',                     '~> 1.2.2'
gem 'rails',                  '~> 5.2.3'
gem 'redis',                  '~> 4.1.3'
gem 'rubyzip'
gem 'config',                 '~> 2.2' # this gem provides our Settings.xxx mechanism
gem 'remotipart',             '~> 1.4'
gem 'rest-client',            '~> 2.1' # needed for scheduled smoke testing plus others
gem 'sass-rails',             '~> 6.0.0'
gem 'scheduler_daemon',       git: 'https://github.com/jalkoby/scheduler_daemon.git'
gem 'susy',                   '~> 2.2.14'
gem 'sentry-raven',           '~> 2.13.0'
gem 'simple_form',            '~> 5.0.1'
gem 'sprockets-rails',        '~> 3.2.1'
gem 'state_machine',          '~> 1.2.0'
gem 'state_machines-activerecord'
gem 'state_machines-audit_trail'
gem 'tzinfo-data'
gem 'uglifier',                '>= 1.3.0'
gem 'zendesk_api'  ,           '1.24.0'
gem 'sidekiq',                 '~> 5.2.7'
gem 'utf8-cleaner',            '~> 0.2'
gem 'colorize'
gem 'shell-spinner', '~> 1.0', '>= 1.0.4'
gem 'ruby-progressbar'
gem 'geckoboard-ruby'
gem 'posix-spawn', '~> 0.3.13'
gem 'laa-fee-calculator-client', '~> 1.1'
gem 'wicked_pdf', '~> 1.4'

group :production, :devunicorn do
  gem 'rails_12factor', '0.0.3'
  gem 'unicorn-rails', '2.2.1'
  gem 'unicorn-worker-killer', '~> 0.4.4'
end

group :development, :devunicorn, :test do
  gem 'annotate'
  gem 'brakeman', :require => false
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'dotenv-rails'
  gem 'guard-cucumber'
  gem 'guard-jasmine', '~> 3.1'
  gem 'guard-livereload', '>= 2.5.2'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'jasmine', '~> 3.5'
  gem 'jasmine_selenium_runner', require: false
  gem 'listen', '~> 3.2.1'
  gem 'meta_request'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'puma'
  gem 'rack-livereload', '~> 0.3.16'
  gem 'rspec-rails'
  gem 'rspec-collection_matchers'
  gem 'net-ssh'
  gem 'net-scp'
  gem 'rubocop', '~> 0.79'
  gem 'rubocop-rspec'
  gem 'rubocop-rails'
  gem 'rubocop-performance'
  gem 'site_prism', '~> 3.4'
end

group :test do
  gem 'axe-matchers', '~> 2.5'
  gem 'capybara-selenium'
  gem 'capybara', '~> 3.30'
  gem 'climate_control'
  gem 'codeclimate-test-reporter', require: false
  gem 'cucumber-rails', '~> 2.0.0', require: false
  gem 'database_cleaner'
  gem 'i18n-tasks'
  gem 'json_spec'
  gem 'kaminari-rspec'
  gem 'launchy', '~> 2.4.3'
  gem 'rails-controller-testing'
  gem 'rspec-mocks'
  gem 'shoulda-matchers', '>= 4.0.0.rc1'
  gem 'simplecov-csv', require: false
  gem 'simplecov-multi', require: false
  gem 'simplecov', require: false
  gem 'test-prof'
  gem 'timecop'
  gem 'vcr'
  gem 'webdrivers', '~> 4.2', require: false
  gem 'webmock'
end
