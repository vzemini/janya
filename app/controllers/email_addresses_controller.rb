# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class EmailAddressesController < ApplicationController
  before_action :find_user, :require_admin_or_current_user
  before_action :find_email_address, :only => [:update, :destroy]
  require_sudo_mode :create, :update, :destroy

  def index
    @addresses = @user.email_addresses.order(:id).where(:is_default => false).to_a
    @address ||= EmailAddress.new
  end

  def create
    saved = false
    if @user.email_addresses.count <= Setting.max_additional_emails.to_i
      @address = EmailAddress.new(:user => @user, :is_default => false)
      @address.safe_attributes = params[:email_address]
      saved = @address.save
    end

    respond_to do |format|
      format.html {
        if saved
          redirect_to user_email_addresses_path(@user)
        else
          index
          render :action => 'index'
        end
      }
      format.js {
        @address = nil if saved
        index
        render :action => 'index'
      }
    end
  end

  def update
    if params[:notify].present?
      @address.notify = params[:notify].to_s
    end
    @address.save

    respond_to do |format|
      format.html {
        redirect_to user_email_addresses_path(@user)
      }
      format.js {
        @address = nil
        index
        render :action => 'index'
      }
    end
  end

  def destroy
    @address.destroy

    respond_to do |format|
      format.html {
        redirect_to user_email_addresses_path(@user)
      }
      format.js {
        @address = nil
        index
        render :action => 'index'
      }
    end
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  end

  def find_email_address
    @address = @user.email_addresses.where(:is_default => false).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def require_admin_or_current_user
    unless @user == User.current
      require_admin
    end
  end
end
