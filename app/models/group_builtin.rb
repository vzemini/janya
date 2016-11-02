# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class GroupBuiltin < Group
  validate :validate_uniqueness, :on => :create

  def validate_uniqueness
    errors.add :base, 'The builtin group already exists.' if self.class.exists?
  end

  def builtin?
    true
  end

  def destroy
    false
  end

  def user_added(user)
    raise 'Cannot add users to a builtin group'
  end

  class << self
    def load_instance
      return nil if self == GroupBuiltin
      instance = order('id').first || create_instance
    end

    def create_instance
      raise 'The builtin group already exists.' if exists?
      instance = new
      instance.lastname = name
      instance.save :validate => false
      raise 'Unable to create builtin group.' if instance.new_record?
      instance
    end
    private :create_instance
  end
end

require_dependency "group_anonymous"
require_dependency "group_non_member"
