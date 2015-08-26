require 'simplecov'
SimpleCov.start
SimpleCov.start do
  add_filter "_spec.rb"
  add_filter "spec/"
  add_filter 'config/'
  add_filter 'db/seeds'

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "FormBuilders", 'app/form_builders'
  add_group "Helpers", 'app/helpers'
  add_group "API", 'app/interfaces/api'
  add_group 'Presenters', '/app/presenters'


  # add_filter "\/factories\/"
end

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['ADP_API_USER'] = 'api_user'
ENV['ADP_API_PASS'] = 'api_password'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'shoulda/matchers'
require 'paperclip/matchers'
require 'webmock/rspec'

require 'flip'
Feature.feature(:api, default: true) #ensures api is switched on for rspec suite
include ActionDispatch::TestProcess #required for fixture_file_upload

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

WebMock.disable_net_connect!(allow: [/codeclimate/, /latest\/meta-data\/iam\/security\-credentials/, /api\/advocates/])

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.include Paperclip::Shoulda::Matchers
  config.include ActionView::TestCase::Behavior, file_path: %r{spec/presenters}

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.create :vat_rate, effective_date: Date.new(1960, 1, 1)
  end

  config.after(:suite) do
    FileUtils.rm_rf('./public/assets/test/images/') #to delete files from filesystem that were generated during rspec tests
    VatRate.delete_all
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
