# frozen_string_literal: true

RSpec.configure do |config|
  # Idea from:
  #  https://jacopretorius.net/2018/07/cross-site-forgery-protection-in-rails-tests.html
  #
  # Tests normally disable forgery protection at the action_controller level.

  # For testing requests/controllers that should NOT implement
  # the default (`protect_from_forgery with: :exception`)
  # this will enable it at the action_controller level so
  # you can test the requests function regardless.
  #
  config.around(:each, allow_forgery_protection: true) do |example|
    original_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    begin
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original_forgery_protection
    end
  end
end
