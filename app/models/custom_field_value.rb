# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CustomFieldValue
  attr_accessor :custom_field, :customized, :value, :value_was

  def initialize(attributes={})
    attributes.each do |name, v|
      send "#{name}=", v
    end
  end

  def custom_field_id
    custom_field.id
  end

  def true?
    self.value == '1'
  end

  def editable?
    custom_field.editable?
  end

  def visible?
    custom_field.visible?
  end

  def required?
    custom_field.is_required?
  end

  def to_s
    value.to_s
  end

  def value=(v)
    @value = custom_field.set_custom_field_value(self, v)
  end

  def validate_value
    custom_field.validate_custom_value(self).each do |message|
      customized.errors.add(:base, custom_field.name + ' ' + message)
    end
  end
end
