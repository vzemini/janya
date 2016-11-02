# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class ProjectEnumerationsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  def update
    if params[:enumerations]
      saved = Project.transaction do
        params[:enumerations].each do |id, activity|
          @project.update_or_create_time_entry_activity(id, activity)
        end
      end
      if saved
        flash[:notice] = l(:notice_successful_update)
      end
    end

    redirect_to settings_project_path(@project, :tab => 'activities')
  end

  def destroy
    @project.time_entry_activities.each do |time_entry_activity|
      time_entry_activity.destroy(time_entry_activity.parent)
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to settings_project_path(@project, :tab => 'activities')
  end
end
