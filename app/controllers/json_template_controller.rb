class JsonTemplateController < ApplicationController
  skip_load_and_authorize_resource only: %i[show]

  before_action :schema, only: :show

  def show
    render json: schema
  end

  private

  def schema
    @schema ||= ClaimJsonSchemaValidator.send(schema_params[:schema].to_sym)
  end

  def schema_params
    params.permit(:schema)
  end
end
