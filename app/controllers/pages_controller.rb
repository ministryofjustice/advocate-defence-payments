class PagesController < ApplicationController
  skip_load_and_authorize_resource
  before_action :suppress_hotline_link

  def tandcs; end

  def vendor_tandcs; end

  def contact_us; end

  def api_landing; end

  def api_release_notes; end

  def timed_retention; end

  def hardship_claims; end
end
