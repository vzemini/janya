# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class JournalDetail < ActiveRecord::Base
  belongs_to :journal
  attr_protected :id

  def custom_field
    if property == 'cf'
      @custom_field ||= CustomField.find_by_id(prop_key)
    end
  end

  def value=(arg)
    write_attribute :value, normalize(arg)
  end

  def old_value=(arg)
    write_attribute :old_value, normalize(arg)
  end

  private

  def normalize(v)
    case v
    when true
      "1"
    when false
      "0"
    when Date
      v.strftime("%Y-%m-%d")
    else
      v
    end
  end
end
