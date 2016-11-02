# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module AuthSourcesHelper
  def auth_source_partial_name(auth_source)
    "form_#{auth_source.class.name.underscore}"
  end
end
