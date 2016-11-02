# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class MemberRole < ActiveRecord::Base
  belongs_to :member
  belongs_to :role

  after_destroy :remove_member_if_empty

  after_create :add_role_to_group_users, :add_role_to_subprojects
  after_destroy :remove_inherited_roles

  validates_presence_of :role
  validate :validate_role_member
  attr_protected :id

  def validate_role_member
    errors.add :role_id, :invalid if role && !role.member?
  end

  def inherited?
    !inherited_from.nil?
  end

  # Destroys the MemberRole without destroying its Member if it doesn't have
  # any other roles
  def destroy_without_member_removal
    @member_removal = false
    destroy
  end

  private

  def remove_member_if_empty
    if @member_removal != false && member.roles.empty?
      member.destroy
    end
  end

  def add_role_to_group_users
    if member.principal.is_a?(Group) && !inherited?
      member.principal.users.each do |user|
        user_member = Member.find_or_new(member.project_id, user.id)
        user_member.member_roles << MemberRole.new(:role => role, :inherited_from => id)
        user_member.save!
      end
    end
  end

  def add_role_to_subprojects
    member.project.children.each do |subproject|
      if subproject.inherit_members?
        child_member = Member.find_or_new(subproject.id, member.user_id)
        child_member.member_roles << MemberRole.new(:role => role, :inherited_from => id)
        child_member.save!
      end
    end
  end

  def remove_inherited_roles
    MemberRole.where(:inherited_from => id).destroy_all
  end
end
