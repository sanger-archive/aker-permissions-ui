class ApplicationController < ActionController::Base
  include JWTCredentials

  helper_method :jwt_provided?
  helper_method :current_user
end
