# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CustomFieldsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :build_new_custom_field, :only => [:new, :create]
  before_action :find_custom_field, :only => [:edit, :update, :destroy]
  accept_api_auth :index

  def index
    respond_to do |format|
      format.html {
        @custom_fields_by_type = CustomField.all.group_by {|f| f.class.name }
      }
      format.api {
        @custom_fields = CustomField.all
      }
    end
  end

  def new
    @custom_field.field_format = 'string' if @custom_field.field_format.blank?
    @custom_field.default_value = nil
  end

  def create
    if @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
      redirect_to edit_custom_field_path(@custom_field)
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @custom_field.safe_attributes = params[:custom_field]
    if @custom_field.save
      call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default edit_custom_field_path(@custom_field)
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
    begin
      @custom_field.destroy
    rescue
      flash[:error] = l(:error_can_not_delete_custom_field)
    end
    redirect_to custom_fields_path(:tab => @custom_field.class.name)
  end

  private

  def build_new_custom_field
    @custom_field = CustomField.new_subclass_instance(params[:type])
    if @custom_field.nil?
      render :action => 'select_type'
    else
      @custom_field.safe_attributes = params[:custom_field]
    end
  end

  def find_custom_field
    @custom_field = CustomField.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
