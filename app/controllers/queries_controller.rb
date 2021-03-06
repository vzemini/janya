# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

class QueriesController < ApplicationController
  menu_item :issues
  before_action :find_query, :except => [:new, :create, :index]
  before_action :find_optional_project, :only => [:new, :create]

  accept_api_auth :index

  include QueriesHelper

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end
    scope = query_class.visible
    @query_count = scope.count
    @query_pages = Paginator.new @query_count, @limit, params['page']
    @queries = scope.
                    order("#{Query.table_name}.name").
                    limit(@limit).
                    offset(@offset).
                    to_a
    respond_to do |format|
      format.html {render_error :status => 406}
      format.api
    end
  end

  def new
    @query = query_class.new
    @query.user = User.current
    @query.project = @project
    @query.build_from_params(params)
  end

  def create
    @query = query_class.new
    @query.user = User.current
    @query.project = @project
    update_query_from_params

    if @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_items(:query_id => @query)
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    update_query_from_params

    if @query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_items(:query_id => @query)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @query.destroy
    redirect_to_items(:set_filter => 1)
  end

  private

  def find_query
    @query = Query.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update_query_from_params
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.build_from_params(params)
    @query.column_names = nil if params[:default_columns]
    @query.sort_criteria = params[:query] && params[:query][:sort_criteria]
    @query.name = params[:query] && params[:query][:name]
    if User.current.allowed_to?(:manage_public_queries, @query.project) || User.current.admin?
      @query.visibility = (params[:query] && params[:query][:visibility]) || Query::VISIBILITY_PRIVATE
      @query.role_ids = params[:query] && params[:query][:role_ids]
    else
      @query.visibility = Query::VISIBILITY_PRIVATE
    end
    @query
  end

  def redirect_to_items(options)
    method = "redirect_to_#{@query.class.name.underscore}"
    send method, options
  end

  def redirect_to_issue_query(options)
    if params[:gantt]
      if @project
        redirect_to project_gantt_path(@project, options)
      else
        redirect_to issues_gantt_path(options)
      end
    else
      redirect_to _project_issues_path(@project, options)
    end
  end

  def redirect_to_time_entry_query(options)
    redirect_to _time_entries_path(@project, nil, options)
  end

  # Returns the Query subclass, IssueQuery by default
  # for compatibility with previous behaviour
  def query_class
    Query.get_subclass(params[:type] || 'IssueQuery')
  end
end
