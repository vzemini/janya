# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class IssueStatusesController < ApplicationController
  layout 'admin'

  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  accept_api_auth :index

  def index
    @issue_statuses = IssueStatus.sorted.to_a
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.api
    end
  end

  def new
    @issue_status = IssueStatus.new
  end

  def create
    @issue_status = IssueStatus.new
    @issue_status.safe_attributes = params[:issue_status]
    if @issue_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to issue_statuses_path
    else
      render :action => 'new'
    end
  end

  def edit
    @issue_status = IssueStatus.find(params[:id])
  end

  def update
    @issue_status = IssueStatus.find(params[:id])
    @issue_status.safe_attributes = params[:issue_status]
    if @issue_status.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to issue_statuses_path(:page => params[:page])
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.js { head 422 }
      end
    end
  end

  def destroy
    IssueStatus.find(params[:id]).destroy
    redirect_to issue_statuses_path
  rescue
    flash[:error] = l(:error_unable_delete_issue_status)
    redirect_to issue_statuses_path
  end

  def update_issue_done_ratio
    if request.post? && IssueStatus.update_issue_done_ratios
      flash[:notice] = l(:notice_issue_done_ratios_updated)
    else
      flash[:error] =  l(:error_issue_done_ratios_not_updated)
    end
    redirect_to issue_statuses_path
  end
end
