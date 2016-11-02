# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class WikisController < ApplicationController
  menu_item :settings
  before_action :find_project, :authorize

  # Create or update a project's wiki
  def edit
    @wiki = @project.wiki || Wiki.new(:project => @project)
    @wiki.safe_attributes = params[:wiki]
    @wiki.save if request.post?
  end

  # Delete a project's wiki
  def destroy
    if request.post? && params[:confirm] && @project.wiki
      @project.wiki.destroy
      redirect_to settings_project_path(@project, :tab => 'wiki')
    end
  end
end
