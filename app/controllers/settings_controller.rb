# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class SettingsController < ApplicationController
  layout 'admin'
  menu_item :plugins, :only => :plugin

  helper :queries

  before_action :require_admin

  require_sudo_mode :index, :edit, :plugin

  def index
    edit
    render :action => 'edit'
  end

  def edit
    @notifiables = Janya::Notifiable.all
    if request.post?
      if Setting.set_all_from_params(params[:settings])
        flash[:notice] = l(:notice_successful_update)
      end
      redirect_to settings_path(:tab => params[:tab])
    else
      @options = {}
      user_format = User::USER_FORMATS.collect{|key, value| [key, value[:setting_order]]}.sort{|a, b| a[1] <=> b[1]}
      @options[:user_format] = user_format.collect{|f| [User.current.name(f[0]), f[0].to_s]}
      @deliveries = ActionMailer::Base.perform_deliveries

      @guessed_host_and_path = request.host_with_port.dup
      @guessed_host_and_path << ('/'+ Janya::Utils.relative_url_root.gsub(%r{^\/}, '')) unless Janya::Utils.relative_url_root.blank?

      @commit_update_keywords = Setting.commit_update_keywords.dup
      @commit_update_keywords = [{}] unless @commit_update_keywords.is_a?(Array) && @commit_update_keywords.any?

      Janya::Themes.rescan
    end
  end

  def plugin
    @plugin = Janya::Plugin.find(params[:id])
    unless @plugin.configurable?
      render_404
      return
    end

    if request.post?
      Setting.send "plugin_#{@plugin.id}=", params[:settings].permit!.to_h
      flash[:notice] = l(:notice_successful_update)
      redirect_to plugin_settings_path(@plugin)
    else
      @partial = @plugin.settings[:partial]
      @settings = Setting.send "plugin_#{@plugin.id}"
    end
  rescue Janya::PluginNotFound
    render_404
  end
end
