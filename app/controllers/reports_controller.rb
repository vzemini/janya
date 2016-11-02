# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

class ReportsController < ApplicationController
  menu_item :issues
  before_action :find_project, :authorize, :find_issue_statuses

  def issue_report
    @trackers = @project.rolled_up_trackers(false).visible
    @versions = @project.shared_versions.sort
    @priorities = IssuePriority.all.reverse
    @categories = @project.issue_categories
    @assignees = (Setting.issue_group_assignment? ? @project.principals : @project.users).sort
    @authors = @project.users.sort
    @subprojects = @project.descendants.visible

    @issues_by_tracker = Issue.by_tracker(@project)
    @issues_by_version = Issue.by_version(@project)
    @issues_by_priority = Issue.by_priority(@project)
    @issues_by_category = Issue.by_category(@project)
    @issues_by_assigned_to = Issue.by_assigned_to(@project)
    @issues_by_author = Issue.by_author(@project)
    @issues_by_subproject = Issue.by_subproject(@project) || []

    render :template => "reports/issue_report"
  end

  def issue_report_details
    case params[:detail]
    when "tracker"
      @field = "tracker_id"
      @rows = @project.rolled_up_trackers(false).visible
      @data = Issue.by_tracker(@project)
      @report_title = l(:field_tracker)
    when "version"
      @field = "fixed_version_id"
      @rows = @project.shared_versions.sort
      @data = Issue.by_version(@project)
      @report_title = l(:field_version)
    when "priority"
      @field = "priority_id"
      @rows = IssuePriority.all.reverse
      @data = Issue.by_priority(@project)
      @report_title = l(:field_priority)
    when "category"
      @field = "category_id"
      @rows = @project.issue_categories
      @data = Issue.by_category(@project)
      @report_title = l(:field_category)
    when "assigned_to"
      @field = "assigned_to_id"
      @rows = (Setting.issue_group_assignment? ? @project.principals : @project.users).sort
      @data = Issue.by_assigned_to(@project)
      @report_title = l(:field_assigned_to)
    when "author"
      @field = "author_id"
      @rows = @project.users.sort
      @data = Issue.by_author(@project)
      @report_title = l(:field_author)
    when "subproject"
      @field = "project_id"
      @rows = @project.descendants.visible
      @data = Issue.by_subproject(@project) || []
      @report_title = l(:field_subproject)
    else
      render_404
    end
  end

  private

  def find_issue_statuses
    @statuses = IssueStatus.sorted.to_a
  end
end
