# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class Document < ActiveRecord::Base
  include Janya::SafeAttributes
  belongs_to :project
  belongs_to :category, :class_name => "DocumentCategory"
  acts_as_attachable :delete_permission => :delete_documents
  acts_as_customizable

  acts_as_searchable :columns => ['title', "#{table_name}.description"],
                     :preload => :project
  acts_as_event :title => Proc.new {|o| "#{l(:label_document)}: #{o.title}"},
                :author => Proc.new {|o| o.attachments.reorder("#{Attachment.table_name}.created_on ASC").first.try(:author) },
                :url => Proc.new {|o| {:controller => 'documents', :action => 'show', :id => o.id}}
  acts_as_activity_provider :scope => preload(:project)

  validates_presence_of :project, :title, :category
  validates_length_of :title, :maximum => 255
  attr_protected :id

  after_create :send_notification

  scope :visible, lambda {|*args|
    joins(:project).
    where(Project.allowed_to_condition(args.shift || User.current, :view_documents, *args))
  }

  safe_attributes 'category_id', 'title', 'description', 'custom_fields', 'custom_field_values'

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_documents, project)
  end

  def initialize(attributes=nil, *args)
    super
    if new_record?
      self.category ||= DocumentCategory.default
    end
  end

  def updated_on
    unless @updated_on
      a = attachments.last
      @updated_on = (a && a.created_on) || created_on
    end
    @updated_on
  end

  def notified_users
    project.notified_users.reject {|user| !visible?(user)}
  end

  private

  def send_notification
    if Setting.notified_events.include?('document_added')
      Mailer.document_added(self).deliver
    end
  end
end
