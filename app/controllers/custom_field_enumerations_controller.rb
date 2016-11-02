# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CustomFieldEnumerationsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_custom_field
  before_action :find_enumeration, :only => :destroy

  helper :custom_fields

  def index
    @values = @custom_field.enumerations.order(:position)
  end

  def create
    @value = @custom_field.enumerations.build
    @value.safe_attributes = params[:custom_field_enumeration]
    @value.save
    respond_to do |format|
      format.html { redirect_to custom_field_enumerations_path(@custom_field) }
      format.js
    end
  end

  def update_each
    saved = CustomFieldEnumeration.update_each(@custom_field, params[:custom_field_enumerations]) do |enumeration, enumeration_attributes|
      enumeration.safe_attributes = enumeration_attributes
    end
    if saved
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :action => 'index'
  end

  def destroy
    reassign_to = @custom_field.enumerations.find_by_id(params[:reassign_to_id])
    if reassign_to.nil? && @value.in_use?
      @enumerations = @custom_field.enumerations - [@value]
      render :action => 'destroy'
      return
    end
    @value.destroy(reassign_to)
    redirect_to custom_field_enumerations_path(@custom_field)
  end

  private

  def find_custom_field
    @custom_field = CustomField.find(params[:custom_field_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_enumeration
    @value = @custom_field.enumerations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
