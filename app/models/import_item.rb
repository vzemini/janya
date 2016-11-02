# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class ImportItem < ActiveRecord::Base
  belongs_to :import

  validates_presence_of :import_id, :position
end
