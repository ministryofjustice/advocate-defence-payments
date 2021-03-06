class API::Logger < Grape::Middleware::Base
  def before
    log_api_request(env['REQUEST_METHOD'], env['PATH_INFO'], env['rack.request.form_hash'])
  end

  def after
    log_api_response(@app_response.first.to_s) if @app_response
    @app_response # this must return @app_response or nil
  end

  private

  def log_api_request(method, path, data)
    log_api('api-request', method: method, path: path, data: data)
  end

  def log_api_response(status)
    log_api('api-response', status: status, response_body: response_body)
  end

  def response_body
    JSON.parse(@app_response[2].first)
  rescue JSON::ParserError
    Rails.logger.error "JSON::Parser error parsing: \n#{@app_response[2].first}"
  end

  def log_api(api_type, data)
    api_request = { log_type: api_type, timestamp: Time.now }.merge!(data)
    Rails.logger.info api_request.to_json
  end
end
