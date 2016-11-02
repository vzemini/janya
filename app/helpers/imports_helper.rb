# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module ImportsHelper
  def options_for_mapping_select(import, field, options={})
    tags = "".html_safe
    blank_text = options[:required] ? "-- #{l(:actionview_instancetag_blank_option)} --" : "&nbsp;".html_safe
    tags << content_tag('option', blank_text, :value => '')
    tags << options_for_select(import.columns_options, import.mapping[field])
    if values = options[:values]
      tags << content_tag('option', '--', :disabled => true)
      tags << options_for_select(values.map {|text, value| [text, "value:#{value}"]}, import.mapping[field])
    end
    tags
  end

  def mapping_select_tag(import, field, options={})
    name = "import_settings[mapping][#{field}]"
    select_tag name, options_for_mapping_select(import, field, options), :id => "import_mapping_#{field}"
  end

  # Returns the options for the date_format setting
  def date_format_options
    Import::DATE_FORMATS.map do |f|
      format = f.gsub('%', '').gsub(/[dmY]/) do
        {'d' => 'DD', 'm' => 'MM', 'Y' => 'YYYY'}[$&]
      end
      [format, f]
    end
  end
end
