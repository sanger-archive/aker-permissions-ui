class StampForm

  # ActiveModel plumbing to make `form_for` work
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

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

      stamp.set_permissions_to(convert_permissions)
    end
  rescue
    false
  end

  def self.from_stamp(stamp)
    new(id: stamp.id, name: stamp.name,
        user_writers: stamp_permitted(stamp, :edit, false),
        group_writers: stamp_permitted(stamp, :edit, true),
        user_spenders: stamp_permitted(stamp, :consume, false),
        group_spenders: stamp_permitted(stamp, :consume, true))
  end

  private

  def convert_permissions
    permitted = []
    add_to_permission(permitted, user_writers, false, :edit)
    add_to_permission(permitted, group_writers, true, :edit)
    add_to_permission(permitted, user_spenders, false, :consume)
    add_to_permission(permitted, group_spenders, true, :consume)
    permitted
  end

  def add_to_permission(permitted, people, is_group, permission_type)
    people&.split(',')&.each do |name|
      name = fixname(name, is_group)
      permitted.push({ permitted: name, permission_type: permission_type })
    end
  end

  def fixname(name, is_group)
    name = name.strip.downcase
    name += '@sanger.ac.uk' unless (is_group || name.include?('@'))
    return name
  end

  def self.stamp_permitted(stamp, permission_type, groups)
    permission_type = permission_type.to_sym
    perms = stamp.permissions.select { |p| p.permission_type.to_sym==permission_type && p.permitted.include?('@')!=groups }.
      map { |p| p.permitted }
    if permission_type==:read
      if groups
        perms.delete('world')
      elsif stamp.owner_id
        perms.delete(stamp.owner_id.downcase)
      end
    end
    if permission_type==:write && !groups && stamp.owner_id
      perms.delete(stamp.owner_id.downcase)
    end
    perms.join(',')
  end

end