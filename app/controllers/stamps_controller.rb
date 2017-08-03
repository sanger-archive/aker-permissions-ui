class StampsController < ApplicationController
  include JWTCredentials

  def index
    @all_stamps = StampClient::Stamp.all
    @owned_stamps = @all_stamps.select{ |s| s.owner_id.eql?(current_user.email) }
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
