# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class Group < Principal
  include Janya::SafeAttributes

  has_and_belongs_to_many :users,
                          :join_table   => "#{table_name_prefix}groups_users#{table_name_suffix}",
                          :after_add => :user_added,
                          :after_remove => :user_removed

  acts_as_customizable

  validates_presence_of :lastname
  validates_uniqueness_of :lastname, :case_sensitive => false
  validates_length_of :lastname, :maximum => 255
  attr_protected :id

  self.valid_statuses = [STATUS_ACTIVE]

  before_destroy :remove_references_before_destroy

  scope :sorted, lambda { order(:type => :asc, :lastname => :asc) }
  scope :named, lambda {|arg| where("LOWER(#{table_name}.lastname) = LOWER(?)", arg.to_s.strip)}
  scope :givable, lambda {where(:type => 'Group')}

  safe_attributes 'name',
    'user_ids',
    'custom_field_values',
    'custom_fields',
    :if => lambda {|group, user| user.admin? && !group.builtin?}

  def to_s
    name.to_s
  end

  def name
    lastname
  end

  def name=(arg)
    self.lastname = arg
  end

  def builtin_type
    nil
  end

  # Return true if the group is a builtin group
  def builtin?
    false
  end

  # Returns true if the group can be given to a user
  def givable?
    !builtin?
  end

  def user_added(user)
    members.each do |member|
      next if member.project.nil?
      user_member = Member.find_by_project_id_and_user_id(member.project_id, user.id) || Member.new(:project_id => member.project_id, :user_id => user.id)
      member.member_roles.each do |member_role|
        user_member.member_roles << MemberRole.new(:role => member_role.role, :inherited_from => member_role.id)
      end
      user_member.save!
    end
  end

  def user_removed(user)
    members.each do |member|
      MemberRole.
        joins(:member).
        where("#{Member.table_name}.user_id = ? AND #{MemberRole.table_name}.inherited_from IN (?)", user.id, member.member_role_ids).
        each(&:destroy)
    end
  end

  def self.human_attribute_name(attribute_key_name, *args)
    attr_name = attribute_key_name.to_s
    if attr_name == 'lastname'
      attr_name = "name"
    end
    super(attr_name, *args)
  end

  def self.anonymous
    GroupAnonymous.load_instance
  end

  def self.non_member
    GroupNonMember.load_instance
  end

  private

  # Removes references that are not handled by associations
  def remove_references_before_destroy
    return if self.id.nil?

    Issue.where(['assigned_to_id = ?', id]).update_all('assigned_to_id = NULL')
  end
end

require_dependency "group_builtin"
