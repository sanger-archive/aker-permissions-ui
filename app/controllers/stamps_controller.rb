class StampsController < ApplicationController
  def index
    @stamps = StampClient::Stamp.all
  end

  def new
  end
end
