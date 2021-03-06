# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

class AdminController < ApplicationController
  layout 'admin'
  menu_item :projects, :only => :projects
  menu_item :plugins, :only => :plugins
  menu_item :info, :only => :info

  before_action :require_admin
  helper :sort
  include SortHelper

  def index
    @no_configuration_data = Janya::DefaultData::Loader::no_data?
  end

  def projects
    @status = params[:status] || 1

    scope = Project.status(@status).sorted
    scope = scope.like(params[:name]) if params[:name].present?

    @project_count = scope.count
    @project_pages = Paginator.new @project_count, per_page_option, params['page']
    @projects = scope.limit(@project_pages.per_page).offset(@project_pages.offset).to_a

    render :action => "projects", :layout => false if request.xhr?
  end

  def plugins
    @plugins = Janya::Plugin.all
  end

  # Loads the default configuration
  # (roles, trackers, statuses, workflow, enumerations)
  def default_configuration
    if request.post?
      begin
        Janya::DefaultData::Loader::load(params[:lang])
        flash[:notice] = l(:notice_default_data_loaded)
      rescue Exception => e
        flash[:error] = l(:error_can_t_load_default_data, ERB::Util.h(e.message))
      end
    end
    redirect_to admin_path
  end

  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = Mailer.test_email(User.current).deliver
      flash[:notice] = l(:notice_email_sent, ERB::Util.h(User.current.mail))
    rescue Exception => e
      flash[:error] = l(:notice_email_error, ERB::Util.h(Janya::CodesetUtil.replace_invalid_utf8(e.message.dup)))
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to settings_path(:tab => 'notifications')
  end

  def info
    @db_adapter_name = ActiveRecord::Base.connection.adapter_name
    @checklist = [
      [:text_default_administrator_account_changed, User.default_admin_account_changed?],
      [:text_file_repository_writable, File.writable?(Attachment.storage_path)],
      ["#{l :text_plugin_assets_writable} (./public/plugin_assets)",   File.writable?(Janya::Plugin.public_directory)],
      [:text_rmagick_available,        Object.const_defined?(:Magick)],
      [:text_convert_available,        Janya::Thumbnail.convert_available?]
    ]
  end
end
