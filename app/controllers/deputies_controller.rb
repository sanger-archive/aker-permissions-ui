class DeputiesController < ApplicationController

  # Get the current deputy selected to use in actions
  before_action :current_deputy, except: :create

  def index
    @all_deputies = StampClient::Deputy.all

    # Collate the deputies for each user
    @collated_deputies = collate_groups_and_users(@all_deputies)
  end

  def create
    deputy_form = DeputyForm.new(deputy_params)

    if deputy_form.save
      flash[:success] = "Deputy created"
    else
      flash[:danger] = "Failed to create deputy: #{deputy_form.errors.full_messages[0]}"
    end

    redirect_to deputies_path
  end

  def show
    DeputyForm.new({ id: @deputy.id })
  end

  def destroy
    if @deputy.destroy
      flash[:success] = "Deputy deleted"
    else
      flash[:danger] = "Failed to delete deputy"
    end

    redirect_to deputies_path
  end

  ###
  # PRIVATE START
  ###
  private

    # This method takes the list of deputies and collates them into group and user deputies for each user
    # { user_email: { user_deputies: [], group_deputies: [] } }
    def collate_groups_and_users(deputies)
      collated_deputies = {}
      deputies.each do |d|
        collated_deputies[d.user_email] = {} if collated_deputies[d.user_email].nil?

        if collated_deputies[d.user_email]["user_deputies"].nil?
          collated_deputies[d.user_email]["user_deputies"] = {}
        end
        if collated_deputies[d.user_email]["group_deputies"].nil?
          collated_deputies[d.user_email]["group_deputies"] = {}
        end

        # Extract the user and group deputies
        d.deputy.include?("@") ?
          collated_deputies[d.user_email]["user_deputies"][d.id] = d.deputy
        :
          collated_deputies[d.user_email]["group_deputies"][d.id] = d.deputy
      end

      collated_deputies
    end

    # Get the deputy linked to the ID
    def current_deputy
      @deputy = (params[:id] && StampClient::Deputy.find(params[:id]).first)
    end

    def deputy_params
      params.require(:deputy).permit(:user_deputies, :group_deputies)
    end

  ###
  # PRIVATE END
  ###
end
