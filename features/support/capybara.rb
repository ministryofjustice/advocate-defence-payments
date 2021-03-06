# frozen_string_literal: true

# Load custom capybara extensions
#
# Idea comes from:
# https://github.com/DavyJonesLocker/capybara-extensions
#
require Rails.root.join('spec','support','capybara_extensions','matchers')

module Capybara
  module DSL
    CapybaraExtensions::Matchers.instance_methods.each do |method|
      define_method method do |*args, &block|
        page.send method, *args, &block
      end
    end
  end

  class Session
    CapybaraExtensions::Matchers.instance_methods.each do |method|
      define_method method do |*args, &block|
        current_scope.send method, *args, &block
      end
    end
  end

  Node::Base.include CapybaraExtensions::Matchers
  Node::Simple.include CapybaraExtensions::Matchers
end

# set minimum threads to 0 (to allow shutdown?!)
# and max threads to 5 (duplicate default development
# settings)
#
Capybara.register_server :puma do |app, port, host|
  require 'rack/handler/puma'
  Rack::Handler::Puma.run(app, Host: host, Port: port, Threads: "0:5")
end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu window-size=1366,768) }
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

# use headless chrome for javascript
Capybara.javascript_driver = :headless_chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10 # seconds
end

if ENV['BROWSER'] == 'chrome'
  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.configure do |config|
    config.default_max_wait_time = 10 # seconds
    config.javascript_driver = :chrome
  end
end


# Capybara defaults to CSS3 selectors rather than XPath.
# If you'd prefer to use XPath, just uncomment this line and adjust any
# selectors in your step definitions to use the XPath syntax.
# Capybara.default_selector = :xpath
