# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class AutoCompletesController < ApplicationController
  before_action :find_project

  def issues
    @issues = []
    q = (params[:q] || params[:term]).to_s.strip
    if q.present?
      scope = Issue.cross_project_scope(@project, params[:scope]).visible
      if q.match(/\A#?(\d+)\z/)
        @issues << scope.find_by_id($1.to_i)
      end
      @issues += scope.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{q}%").order("#{Issue.table_name}.id DESC").limit(10).to_a
      @issues.compact!
    end
    render :layout => false
  end

  private

  def find_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
