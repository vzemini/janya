# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class TrackersController < ApplicationController
  layout 'admin'

  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  accept_api_auth :index

  def index
    @trackers = Tracker.sorted.to_a
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.api
    end
  end

  def new
    @tracker ||= Tracker.new
    @tracker.safe_attributes = params[:tracker]
    @trackers = Tracker.sorted.to_a
    @projects = Project.all
  end

  def create
    @tracker = Tracker.new
    @tracker.safe_attributes = params[:tracker]
    if @tracker.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Tracker.find_by_id(params[:copy_workflow_from]))
        @tracker.workflow_rules.copy(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to trackers_path
      return
    end
    new
    render :action => 'new'
  end

  def edit
    @tracker ||= Tracker.find(params[:id])
    @projects = Project.all
  end

  def update
    @tracker = Tracker.find(params[:id])
    @tracker.safe_attributes = params[:tracker]
    if @tracker.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to trackers_path(:page => params[:page])
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html {
          edit
          render :action => 'edit'
        }
        format.js { head 422 }
      end
    end
  end

  def destroy
    @tracker = Tracker.find(params[:id])
    unless @tracker.issues.empty?
      flash[:error] = l(:error_can_not_delete_tracker)
    else
      @tracker.destroy
    end
    redirect_to trackers_path
  end

  def fields
    if request.post? && params[:trackers]
      params[:trackers].each do |tracker_id, tracker_params|
        tracker = Tracker.find_by_id(tracker_id)
        if tracker
          tracker.core_fields = tracker_params[:core_fields]
          tracker.custom_field_ids = tracker_params[:custom_field_ids]
          tracker.save
        end
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to fields_trackers_path
      return
    end
    @trackers = Tracker.sorted.to_a
    @custom_fields = IssueCustomField.all.sort
  end
end
