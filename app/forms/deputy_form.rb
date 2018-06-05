class DeputyForm
  include ActiveModel::Validations

  validates :user_deputies, allow_blank: true, format: { with: /\A[A-Za-z0-9,._@-]+\z/ }
  validates :group_deputies, allow_blank: true, format: { with: /\A[A-Za-z0-9 ,_]+\z/ }

  ATTRIBUTES = [:id, :user_deputies, :group_deputies]

  attr_accessor(*ATTRIBUTES)

  def initialize(attributes = {})
    # assign attributes dynamically - https://stackoverflow.com/a/26193804
    ATTRIBUTES.each do |attribute|
      value = attributes[attribute]
      send("#{attribute}=", value)
    end
  end

  def save
    # Return false if we have neither users or groups to assign as deputies
    return false if user_deputies.blank? && group_deputies.blank?

    valid? && create_objects
  end

  ###
  # PRIVATE START
  ###
  private

    def create_objects
      save_deputies(user_deputies, true) if user_deputies.present?
      save_deputies(group_deputies) if group_deputies.present?

      # Return true if all users and groups have been saved
      true
    rescue JsonApiClient::Errors::ApiError => e
      errors[:base] << e.env.body["errors"][0]["detail"]

      # Return false if ActiveRecord was not able to save the records correctly
      false
    end

    # Save the user or group deputies after formatting them - if required
    def save_deputies(deputies, user = false)
      # Get the users into a usable array
      deputies_array = deputies.split(',')

      deputies_array.each do |deputy|
        if user
          deputy = deputy.strip.downcase
          deputy += '@sanger.ac.uk' unless deputy.include?('@')
        end
        deputy = StampClient::Deputy.create(deputy: deputy)
      end
    end

  ###
  # PRIVATE END
  ###
end
