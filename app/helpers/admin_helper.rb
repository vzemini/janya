# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module AdminHelper
  def project_status_options_for_select(selected)
    options_for_select([[l(:label_all), ''],
                        [l(:project_status_active), '1'],
                        [l(:project_status_closed), '5'],
                        [l(:project_status_archived), '9']], selected.to_s)
  end

  def plugin_data_for_updates(plugins)
    data = {"v" => Janya::VERSION.to_s, "p" => {}}
    plugins.each do |plugin|
      data["p"].merge! plugin.id => {"v" => plugin.version, "n" => plugin.name, "a" => plugin.author}
    end
    data
  end
end
