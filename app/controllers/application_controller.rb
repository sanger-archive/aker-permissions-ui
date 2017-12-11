class ApplicationController < ActionController::Base
  include JWTCredentials

  protect_from_forgery with: :exception

  helper_method :jwt_provided?
  helper_method :current_user
end
