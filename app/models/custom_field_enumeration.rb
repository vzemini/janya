# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CustomFieldEnumeration < ActiveRecord::Base
  include Janya::SafeAttributes

  belongs_to :custom_field
  attr_accessible :name, :active, :position

  validates_presence_of :name, :position, :custom_field_id
  validates_length_of :name, :maximum => 60
  validates_numericality_of :position, :only_integer => true
  before_create :set_position

  scope :active, lambda { where(:active => true) }

  safe_attributes 'name',
    'active',
    'position'

  def to_s
    name.to_s
  end

  def objects_count
    custom_values.count
  end

  def in_use?
    objects_count > 0
  end

  alias :destroy_without_reassign :destroy
  def destroy(reassign_to=nil)
    if reassign_to
      custom_values.update_all(:value => reassign_to.id.to_s)
    end
    destroy_without_reassign
  end

  def custom_values
    custom_field.custom_values.where(:value => id.to_s)
  end

  def self.update_each(custom_field, attributes)
    return unless attributes.is_a?(Hash)
    transaction do
      attributes.each do |enumeration_id, enumeration_attributes|
        enumeration = custom_field.enumerations.find_by_id(enumeration_id)
        if enumeration
          if block_given?
            yield enumeration, enumeration_attributes
          else
            enumeration.attributes = enumeration_attributes
          end
          unless enumeration.save
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  end

  def self.fields_for_order_statement(table=nil)
    table ||= table_name
    columns = ['position']
    columns.uniq.map {|field| "#{table}.#{field}"}
  end

  private

  def set_position
    max = self.class.where(:custom_field_id => custom_field_id).maximum(:position) || 0
    self.position = max + 1
  end
end
