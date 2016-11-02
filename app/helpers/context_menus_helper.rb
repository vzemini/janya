# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module ContextMenusHelper
  def context_menu_link(name, url, options={})
    options[:class] ||= ''
    if options.delete(:selected)
      options[:class] << ' icon-checked disabled'
      options[:disabled] = true
    end
    if options.delete(:disabled)
      options.delete(:method)
      options.delete(:data)
      options[:onclick] = 'return false;'
      options[:class] << ' disabled'
      url = '#'
    end
    link_to h(name), url, options
  end

  def bulk_update_custom_field_context_menu_link(field, text, value)
    context_menu_link h(text),
      bulk_update_issues_path(:ids => @issue_ids, :issue => {'custom_field_values' => {field.id => value}}, :back_url => @back),
      :method => :post,
      :selected => (@issue && @issue.custom_field_value(field) == value)
  end

  def bulk_update_time_entry_custom_field_context_menu_link(field, text, value)
    context_menu_link h(text),
      bulk_update_time_entries_path(:ids => @time_entries.map(&:id).sort, :time_entry => {'custom_field_values' => {field.id => value}}, :back_url => @back),
      :method => :post,
      :selected => (@time_entry && @time_entry.custom_field_value(field) == value)
  end
end
