Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  PAPERCLIP_STORAGE_OPTIONS = {
    storage: :filesystem,
    path: "public/assets/dev/images/docs/:id_partition/:filename",
    url: "assets/dev/images/docs/:id_partition/:filename"
  }

  REPORDER_STORAGE_OPTIONS = {
    storage: :filesystem,
    path: "public/assets/dev/images/reporders/:id_partition/:filename",
    url: "assets/dev/images/reporders/:id_partition/:filename"
  }

  GA_TRACKER_ID = ENV.fetch('GA_TRACKER_ID', 'UA-37377084-48')

  #Removed to allow for remote device testing (Ipad or other tablets)
  #config.action_controller.asset_host = "http://localhost:3000"

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.default_url_options = { host: ENV["GRAPE_SWAGGER_ROOT_URL"] || 'http://localhost:3000' }
  config.action_mailer.asset_host = config.action_mailer.default_url_options[:host]

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.active_record.raise_in_transactional_callbacks = true

  # enable the ability to preview devise emails
  # And index of all can, be viewed at:
  # using webrick defaults at http://localhost:3000/rails/mailers
  config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

  #Rack livereload for frontend development
  config.middleware.use Rack::LiveReload rescue (puts 'Rack::LiveReload not available')

  config.action_mailer.perform_deliveries = false
  config.action_mailer.delivery_method = :file

  # set local dev vars, uncomment and change delivery_emthod to :smtp
  # config.action_mailer.smtp_settings = {
  #   address:              ENV['SMTP_SERVER'],
  #   port:                 ENV['SMTP_PORT'],
  #   domain:               ENV['SMTP_DOMAIN'],
  #   user_name:            ENV['SMTP_USER'],
  #   password:             ENV['SMTP_PASSWORD'],
  #   authentication:       :login,
  #   enable_starttls_auto: true
  # }

end
