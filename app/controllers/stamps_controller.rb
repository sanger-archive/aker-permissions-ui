class StampsController < ApplicationController
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

end
