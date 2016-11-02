# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class PreviewsController < ApplicationController
  before_action :find_project, :find_attachments

  def issue
    @issue = Issue.visible.find_by_id(params[:id]) unless params[:id].blank?
    if @issue
      @description = params[:issue] && params[:issue][:description]
      if @description && @description.gsub(/(\r?\n|\n\r?)/, "\n") == @issue.description.to_s.gsub(/(\r?\n|\n\r?)/, "\n")
        @description = nil
      end
      # params[:notes] is useful for preview of notes in issue history
      @notes = params[:notes] || (params[:issue] ? params[:issue][:notes] : nil)
    else
      @description = (params[:issue] ? params[:issue][:description] : nil)
    end
    render :layout => false
  end

  def news
    if params[:id].present? && news = News.visible.find_by_id(params[:id])
      @previewed = news
    end
    @text = (params[:news] ? params[:news][:description] : nil)
    render :partial => 'common/preview'
  end

  private

  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
