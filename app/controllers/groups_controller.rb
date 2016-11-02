# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class GroupsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_group, :except => [:index, :new, :create]
  accept_api_auth :index, :show, :create, :update, :destroy, :add_users, :remove_user

  require_sudo_mode :add_users, :remove_user, :create, :update, :destroy, :edit_membership, :destroy_membership

  helper :custom_fields
  helper :principal_memberships

  def index
    respond_to do |format|
      format.html {
        scope = Group.sorted
        scope = scope.like(params[:name]) if params[:name].present?

        @group_count = scope.count
        @group_pages = Paginator.new @group_count, per_page_option, params['page']
        @groups = scope.limit(@group_pages.per_page).offset(@group_pages.offset).to_a
        @user_count_by_group_id = user_count_by_group_id
      }
      format.api {
        scope = Group.sorted
        scope = scope.givable unless params[:builtin] == '1'
        @groups = scope.to_a
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new
    @group.safe_attributes = params[:group]

    respond_to do |format|
      if @group.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_group_path : groups_path)
        }
        format.api  { render :action => 'show', :status => :created, :location => group_url(@group) }
      else
        format.html { render :action => "new" }
        format.api  { render_validation_errors(@group) }
      end
    end
  end

  def edit
  end

  def update
    @group.safe_attributes = params[:group]

    respond_to do |format|
      if @group.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to_referer_or(groups_path) }
        format.api  { render_api_ok }
      else
        format.html { render :action => "edit" }
        format.api  { render_validation_errors(@group) }
      end
    end
  end

  def destroy
    @group.destroy

    respond_to do |format|
      format.html { redirect_to_referer_or(groups_path) }
      format.api  { render_api_ok }
    end
  end

  def new_users
  end

  def add_users
    @users = User.not_in_group(@group).where(:id => (params[:user_id] || params[:user_ids])).to_a
    @group.users << @users
    respond_to do |format|
      format.html { redirect_to edit_group_path(@group, :tab => 'users') }
      format.js
      format.api {
        if @users.any?
          render_api_ok
        else
          render_api_errors "#{l(:label_user)} #{l('activerecord.errors.messages.invalid')}"
        end
      }
    end
  end

  def remove_user
    @group.users.delete(User.find(params[:user_id])) if request.delete?
    respond_to do |format|
      format.html { redirect_to edit_group_path(@group, :tab => 'users') }
      format.js
      format.api { render_api_ok }
    end
  end

  def autocomplete_for_user
    respond_to do |format|
      format.js
    end
  end

  private

  def find_group
    @group = Group.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def user_count_by_group_id
    h = User.joins(:groups).group('group_id').count
    h.keys.each do |key|
      h[key.to_i] = h.delete(key)
    end
    h
  end
end
