# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class FilesController < ApplicationController
  menu_item :files

  before_action :find_project_by_project_id
  before_action :authorize

  helper :sort
  include SortHelper

  def index
    sort_init 'filename', 'asc'
    sort_update 'filename' => "#{Attachment.table_name}.filename",
                'created_on' => "#{Attachment.table_name}.created_on",
                'size' => "#{Attachment.table_name}.filesize",
                'downloads' => "#{Attachment.table_name}.downloads"

    @containers = [Project.includes(:attachments).
                     references(:attachments).reorder(sort_clause).find(@project.id)]
    @containers += @project.versions.includes(:attachments).
                    references(:attachments).reorder(sort_clause).to_a.sort.reverse
    render :layout => !request.xhr?
  end

  def new
    @versions = @project.versions.sort
  end

  def create
    container = (params[:version_id].blank? ? @project : @project.versions.find_by_id(params[:version_id]))
    attachments = Attachment.attach_files(container, params[:attachments])
    render_attachment_warning_if_needed(container)

    if attachments[:files].present?
      if Setting.notified_events.include?('file_added')
        Mailer.attachments_added(attachments[:files]).deliver
      end
      flash[:notice] = l(:label_file_added)
      redirect_to project_files_path(@project)
    else
      flash.now[:error] = l(:label_attachment) + " " + l('activerecord.errors.messages.invalid')
      new
      render :action => 'new'
    end
  end
end
