class StampsController < ApplicationController

  before_action :current_stamp, except: :create

  def index
    @all_stamps = StampClient::Stamp.all
    @owned_stamps = @all_stamps.select{ |s| s.owner_id.eql?(current_user.email) }
  end

  def create
    stamp_form = StampForm.new(stamp_params)

    if stamp_form.save
      flash[:success] = "Stamp created"
    else
      flash[:danger] = "Failed to create stamp: #{stamp_form.errors.full_messages}"
    end
    redirect_to stamps_path
  end

  def show
    make_stamp_form
  end

  def edit
    make_stamp_form
  end

  def update
    stamp_form = StampForm.new(stamp_params.merge(id: params[:id]))
    if stamp_form.save
      flash[:success] = "Stamp updated"
    else
      flash[:danger] = "Failed to update stamp: #{stamp_form.errors.full_messages}"
    end
    redirect_to stamps_path
  end

  def destroy
    if @stamp.destroy
      flash[:success] = "Stamp deleted"
    else
      flash[:danger] = "Failed to delete stamp"
    end
    redirect_to stamps_path
  end

private

  def current_stamp
    @stamp = (params[:id] && StampClient::Stamp.find_with_permissions(params[:id]).first)
  end

  def stamp_params
    params.require(:stamp).permit(:name, :user_editors, :group_editors, :user_consumers, :group_consumers)
  end

  def make_stamp_form
    @stampform = StampForm.from_stamp(@stamp)
  end

end
