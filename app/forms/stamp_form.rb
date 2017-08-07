class StampForm
  ATTRIBUTES = [:id, :name, :user_writers, :group_writers, :user_spenders, :group_spenders]

  attr_accessor *ATTRIBUTES

  def initialize(attributes = {})
    ATTRIBUTES.each do |attribute|
      value = attributes[attribute]
      send("#{attribute}=", value)
    end
  end

  def save
    create_objects
  end

  def create_objects
    ActiveRecord::Base.transaction do
      stamp = StampClient::Stamp.create({name: name})
      stamp.set_permissions_to([{ permission_type: :edit, permitted: [user_writers, group_writers] },
        { permission_type: :consume, permitted: [user_spenders, group_spenders] }])
    end
  rescue
    false
  end

end