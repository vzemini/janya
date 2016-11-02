# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class Change < ActiveRecord::Base
  belongs_to :changeset

  validates_presence_of :changeset_id, :action, :path
  before_save :init_path
  before_validation :replace_invalid_utf8_of_path
  attr_protected :id

  def replace_invalid_utf8_of_path
    self.path      = Janya::CodesetUtil.replace_invalid_utf8(self.path)
    self.from_path = Janya::CodesetUtil.replace_invalid_utf8(self.from_path)
  end

  def init_path
    self.path ||= ""
  end
end
