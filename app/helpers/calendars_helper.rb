# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module CalendarsHelper
  def link_to_previous_month(year, month, options={})
    target_year, target_month = if month == 1
                                  [year - 1, 12]
                                else
                                  [year, month - 1]
                                end

    name = if target_month == 12
             "#{month_name(target_month)} #{target_year}"
           else
             "#{month_name(target_month)}"
           end

    # \xc2\xab(utf-8) = &#171;
    link_to_month(("\xc2\xab " + name), target_year, target_month, options)
  end

  def link_to_next_month(year, month, options={})
    target_year, target_month = if month == 12
                                  [year + 1, 1]
                                else
                                  [year, month + 1]
                                end

    name = if target_month == 1
             "#{month_name(target_month)} #{target_year}"
           else
             "#{month_name(target_month)}"
           end

    # \xc2\xbb(utf-8) = &#187;
    link_to_month((name + " \xc2\xbb"), target_year, target_month, options)
  end

  def link_to_month(link_name, year, month, options={})
    link_to(link_name, {:params => request.query_parameters.merge(:year => year, :month => month)}, options)
  end
end
