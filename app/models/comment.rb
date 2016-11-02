# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class Comment < ActiveRecord::Base
  include Janya::SafeAttributes
  belongs_to :commented, :polymorphic => true, :counter_cache => true
  belongs_to :author, :class_name => 'User'

  validates_presence_of :commented, :author, :comments
  attr_protected :id

  after_create :send_notification

  safe_attributes 'comments'

  private

  def send_notification
    mailer_method = "#{commented.class.name.underscore}_comment_added"
    if Setting.notified_events.include?(mailer_method)
      Mailer.send(mailer_method, self).deliver
    end
  end
end
