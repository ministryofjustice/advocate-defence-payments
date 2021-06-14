# rubocop: disable Rails/ApplicationController
class ServicedownController < ActionController::Base
  layout 'servicedown'

  def show
    respond_to do |format|
      format.html { render :show, status: :service_unavailable }
      format.json { render json: [{ error: 'Service temporarily unavailable' }], status: :service_unavailable }
      format.js { render json: [{ error: 'Service temporarily unavailable' }], status: :service_unavailable }
      format.all { render plain: 'error: Service temporarily unavailable', status: :service_unavailable }
    end
  end
end
# rubocop: enable Rails/ApplicationController
