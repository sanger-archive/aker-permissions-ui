class StampsController < ApplicationController
  include JWTCredentials

  def index
    @all_stamps = StampClient::Stamp.all
    @owned_stamps = StampClient::Stamp.where(owner_id: current_user.email).all
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
