# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module RoutesHelper

  # Returns the path to project issues or to the cross-project
  # issue list if project is nil
  def _project_issues_path(project, *args)
    if project
      project_issues_path(project, *args)
    else
      issues_path(*args)
    end
  end

  def _project_news_path(project, *args)
    if project
      project_news_index_path(project, *args)
    else
      news_index_path(*args)
    end
  end

  def _new_project_issue_path(project, *args)
    if project
      new_project_issue_path(project, *args)
    else
      new_issue_path(*args)
    end
  end

  def _project_calendar_path(project, *args)
    project ? project_calendar_path(project, *args) : issues_calendar_path(*args)
  end

  def _project_gantt_path(project, *args)
    project ? project_gantt_path(project, *args) : issues_gantt_path(*args)
  end

  def _time_entries_path(project, issue, *args)
    if project
      project_time_entries_path(project, *args)
    else
      time_entries_path(*args)
    end
  end

  def _report_time_entries_path(project, issue, *args)
    if project
      report_project_time_entries_path(project, *args)
    else
      report_time_entries_path(*args)
    end
  end

  def _new_time_entry_path(project, issue, *args)
    if issue
      new_issue_time_entry_path(issue, *args)
    elsif project
      new_project_time_entry_path(project, *args)
    else
      new_time_entry_path(*args)
    end
  end

  def board_path(board, *args)
    project_board_path(board.project, board, *args)
  end
end
