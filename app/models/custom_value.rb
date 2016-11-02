# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CustomValue < ActiveRecord::Base
  belongs_to :custom_field
  belongs_to :customized, :polymorphic => true
  attr_protected :id

  after_save :custom_field_after_save_custom_value

  def initialize(attributes=nil, *args)
    super
    if new_record? && custom_field && !attributes.key?(:value)
      self.value ||= custom_field.default_value
    end
  end

  # Returns true if the boolean custom value is true
  def true?
    self.value == '1'
  end

  def editable?
    custom_field.editable?
  end

  def visible?
    custom_field.visible?
  end

  def attachments_visible?(user)
    visible? && customized && customized.visible?(user)
  end

  def required?
    custom_field.is_required?
  end

  def to_s
    value.to_s
  end

  private

  def custom_field_after_save_custom_value
    custom_field.after_save_custom_value(self)
  end
end
