# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

module GanttHelper

  def gantt_zoom_link(gantt, in_or_out)
    case in_or_out
    when :in
      if gantt.zoom < 4
        link_to l(:text_zoom_in),
          {:params => request.query_parameters.merge(gantt.params.merge(:zoom => (gantt.zoom + 1)))},
          :class => 'icon icon-zoom-in'
      else
        content_tag(:span, l(:text_zoom_in), :class => 'icon icon-zoom-in').html_safe
      end

    when :out
      if gantt.zoom > 1
        link_to l(:text_zoom_out),
          {:params => request.query_parameters.merge(gantt.params.merge(:zoom => (gantt.zoom - 1)))},
          :class => 'icon icon-zoom-out'
      else
        content_tag(:span, l(:text_zoom_out), :class => 'icon icon-zoom-out').html_safe
      end
    end
  end
end
