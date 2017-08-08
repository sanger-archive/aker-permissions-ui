class StampsController < ApplicationController
  include JWTCredentials

  before_action :current_stamp, except: :create

  def index
    @all_stamps = StampClient::Stamp.all
    @owned_stamps = @all_stamps.select{ |s| s.owner_id.eql?(current_user.email) }
  end

  def new
  end

  def create
    stamp_form = StampForm.new(stamp_params)

    if stamp_form.save
      flash[:success] = "Stamp created"
    else
      flash[:danger] = "Failed to create stamp"
    end
    redirect_to root_path
  end

  def show
  end

  def edit
  end

  def destroy
    if @stamp.deactivate
      flash[:success] = "Stamp deleted"
    else
      flash[:danger] = @stamp.errors.empty? ? "This stamp cannot be deleted." : @stamp.errors.full_messages.join(" ")
    end
    redirect_to root_path
  end

  def current_user
    u = session["user"]
    if u.is_a? Hash
      u = User.new(u)
    end
    u
  end

  private

  def current_stamp
    @stamp = (params[:id] && StampClient::Stamp.find_with_permissions(params[:id]).first)
  end

  def stamp_params
    params.require(:stamp).permit(:name, :user_writers, :group_writers, :user_spenders, :group_spenders)
  end


end
