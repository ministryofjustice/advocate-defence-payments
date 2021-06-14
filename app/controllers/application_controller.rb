class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :exception unless ENV['DISABLE_CSRF'] == '1'

  include CookieConcern
  before_action :set_default_cookie_usage

  helper_method :current_user_messages_count
  helper_method :signed_in_user_profile_path
  helper_method :current_user_persona_is?

  load_and_authorize_resource

  rescue_from StandardError do |exception|
    raise unless Rails.env.production?

    Sentry.capture_exception(exception)
    redirect_to error_500_url
  end

  rescue_from ActionController::InvalidAuthenticityToken do |_exception|
    redirect_back fallback_location: unauthenticated_root_path
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    raise unless Rails.env.production?

    redirect_to error_404_url
  end

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to root_path_url_for_user, alert: 'Unauthorised'
  end

  def user_for_paper_trail
    current_user.nil? ? 'Unknown' : current_user.persona.class.to_s.humanize
  end

  def current_user_messages_count
    UserMessageStatus.for(current_user).not_marked_as_read.count
  end

  def current_user_persona_is?(persona_class)
    current_user&.persona.is_a?(persona_class)
  end

  def signed_in_user_profile_path
    current_user_persona_class = current_user.persona.class.to_s.underscore
    path_helper_method = "#{current_user_persona_class.pluralize}_admin_#{current_user_persona_class}_path"
    send path_helper_method, current_user.persona_id
  end

  def root_path_url_for_user
    if current_user
      method_name = "after_sign_in_path_for_#{current_user.persona.class.to_s.underscore.downcase}"
      send(method_name)
    else
      new_user_session_url
    end
  end

  def after_sign_out_path_for(_resource, params = {})
    if Rails.env.development? || Rails.env.devunicorn? || RailsHost.dev?
      new_user_session_url
    else
      new_feedback_url(params.merge(type: 'feedback'))
    end
  end

  def after_sign_in_path_for(_resource)
    method_name = "after_sign_in_path_for_#{current_user.persona.class.to_s.underscore.downcase}"
    send(method_name)
  end

  private

  def after_sign_in_path_for_super_admin
    super_admins_root_url
  end

  def after_sign_in_path_for_external_user
    external_users_root_url
  end

  def after_sign_in_path_for_case_worker
    if current_user.persona.admin?
      case_workers_admin_root_url
    else
      case_workers_root_url
    end
  end

  def method_missing(method, *args)
    raise "Unrecognised user type #{Regexp.last_match(1)}" if method.to_s =~ /^after_sign_in_path_for_(.*)/
    super
  end

  def respond_to_missing?(method, include_private = false)
    method.to_s.match?(/^after_sign_in_path_for_(.*)/) ? false : super
  end

  def track_visit(*args)
    (flash.now[:ga] ||= []) << GoogleAnalytics::DataTracking.track(:virtual_page, *args)
  end

  def suppress_hotline_link
    @suppress_contact_us_message = true
  end

  def enable_breadcrumb
    @enable_breadcrumb = true
  end
end
