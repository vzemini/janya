# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class AuthSourcesController < ApplicationController
  layout 'admin'
  menu_item :ldap_authentication

  before_action :require_admin
  before_action :build_new_auth_source, :only => [:new, :create]
  before_action :find_auth_source, :only => [:edit, :update, :test_connection, :destroy]
  require_sudo_mode :update, :destroy

  def index
    @auth_source_pages, @auth_sources = paginate AuthSource, :per_page => 25
  end

  def new
  end

  def create
    if @auth_source.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to auth_sources_path
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @auth_source.safe_attributes = params[:auth_source]
    if @auth_source.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to auth_sources_path
    else
      render :action => 'edit'
    end
  end

  def test_connection
    begin
      @auth_source.test_connection
      flash[:notice] = l(:notice_successful_connection)
    rescue Exception => e
      flash[:error] = l(:error_unable_to_connect, e.message)
    end
    redirect_to auth_sources_path
  end

  def destroy
    unless @auth_source.users.exists?
      @auth_source.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to auth_sources_path
  end

  def autocomplete_for_new_user
    results = AuthSource.search(params[:term])

    render :json => results.map {|result| {
      'value' => result[:login],
      'label' => "#{result[:login]} (#{result[:firstname]} #{result[:lastname]})",
      'login' => result[:login].to_s,
      'firstname' => result[:firstname].to_s,
      'lastname' => result[:lastname].to_s,
      'mail' => result[:mail].to_s,
      'auth_source_id' => result[:auth_source_id].to_s
    }}
  end

  private

  def build_new_auth_source
    @auth_source = AuthSource.new_subclass_instance(params[:type] || 'AuthSourceLdap')
    if @auth_source
      @auth_source.safe_attributes = params[:auth_source]
    else
      render_404
    end
  end

  def find_auth_source
    @auth_source = AuthSource.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
