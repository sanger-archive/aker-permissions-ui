class StampForm
  include ActiveModel::Validations

  validates :name, presence: true, format: { with: /\A[A-Za-z0-9_-]+\z/ }
  validates :user_editors, :user_consumers, allow_blank: true, format: { with: /\A[A-Za-z0-9 ,._@-]+\z/ }
  validates :group_editors, :group_consumers, allow_blank: true, format: { with: /\A[A-Za-z0-9 ,_]+\z/ }

  ATTRIBUTES = [:id, :name, :user_editors, :group_editors, :user_consumers, :group_consumers]

  attr_accessor *ATTRIBUTES

  def initialize(attributes = {})
    ATTRIBUTES.each do |attribute|
      value = attributes[attribute]
      send("#{attribute}=", value)
    end
  end

  def save
    valid? && (id.present? ? update_objects : create_objects)
  end

  def self.from_stamp(stamp)
    new(attributes_from_stamp(stamp))
  end

  private

  def create_objects
    ActiveRecord::Base.transaction do
      stamp = StampClient::Stamp.create({name: name})
      stamp.set_permissions_to(convert_permissions)
      true
    end
  rescue
    false
  end

  def update_objects
    ActiveRecord::Base.transaction do
      stamp = StampClient::Stamp.find_with_permissions(id).first
      stamp.update(name: name)
      stamp.set_permissions_to(convert_permissions)
      true
    end
  rescue
    false
  end

  def convert_permissions
    permitted = []
    add_to_permission(permitted, user_editors, false, :edit)
    add_to_permission(permitted, group_editors, true, :edit)
    add_to_permission(permitted, user_consumers, false, :consume)
    add_to_permission(permitted, group_consumers, true, :consume)
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


  def self.attributes_from_stamp(stamp)
    { id: stamp.id, name: stamp.name,
      user_editors: stamp_permitted(stamp, :edit, false),
      group_editors: stamp_permitted(stamp, :edit, true),
      user_consumers: stamp_permitted(stamp, :consume, false),
      group_consumers: stamp_permitted(stamp, :consume, true)
    }
  end

  def self.stamp_permitted(stamp, permission_type, groups)
    return '' if stamp.permissions.nil?
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
    if permission_type==:edit && !groups && stamp.owner_id
      perms.delete(stamp.owner_id.downcase)
    end
    perms.join(',')
  end

end