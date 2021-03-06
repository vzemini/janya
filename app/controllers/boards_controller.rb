# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

class BoardsController < ApplicationController
  default_search_scope :messages
  before_action :find_project_by_project_id, :find_board_if_available, :authorize
  accept_rss_auth :index, :show

  helper :sort
  include SortHelper
  helper :watchers

  def index
    @boards = @project.boards.preload(:project, :last_message => :author).to_a
    # show the board if there is only one
    if @boards.size == 1
      @board = @boards.first
      show
    end
  end

  def show
    respond_to do |format|
      format.html {
        sort_init 'updated_on', 'desc'
        sort_update 'created_on' => "#{Message.table_name}.id",
                    'replies' => "#{Message.table_name}.replies_count",
                    'updated_on' => "COALESCE(#{Message.table_name}.last_reply_id, #{Message.table_name}.id)"

        @topic_count = @board.topics.count
        @topic_pages = Paginator.new @topic_count, per_page_option, params['page']
        @topics =  @board.topics.
          reorder(:sticky => :desc).
          limit(@topic_pages.per_page).
          offset(@topic_pages.offset).
          order(sort_clause).
          preload(:author, {:last_reply => :author}).
          to_a
        @message = Message.new(:board => @board)
        render :action => 'show', :layout => !request.xhr?
      }
      format.atom {
        @messages = @board.messages.
          reorder(:id => :desc).
          includes(:author, :board).
          limit(Setting.feeds_limit.to_i).
          to_a
        render_feed(@messages, :title => "#{@project}: #{@board}")
      }
    end
  end

  def new
    @board = @project.boards.build
    @board.safe_attributes = params[:board]
  end

  def create
    @board = @project.boards.build
    @board.safe_attributes = params[:board]
    if @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_in_projects
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @board.safe_attributes = params[:board]
    if @board.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to_settings_in_projects
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
    @board.destroy
    redirect_to_settings_in_projects
  end

private
  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'boards')
  end

  def find_board_if_available
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
