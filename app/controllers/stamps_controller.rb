class StampsController < ApplicationController
  include JWTCredentials

  def index
    @stamps = StampClient::Stamp.all
  end

  def new
  end

  def show
  end

  def edit
  end

  def destroy
  end

  def current_user
    u = session["user"]
    if u.is_a? Hash
      u = User.new(u)
    end
    u
  end

end
