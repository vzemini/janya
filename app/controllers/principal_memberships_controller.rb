# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class PrincipalMembershipsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_principal, :only => [:new, :create]
  before_action :find_membership, :only => [:update, :destroy]

  def new
    @projects = Project.active.all
    @roles = Role.find_all_givable
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @members = Member.create_principal_memberships(@principal, params[:membership])
    respond_to do |format|
      format.html { redirect_to_principal @principal }
      format.js
    end
  end

  def update
    @membership.attributes = params[:membership]
    @membership.save
    respond_to do |format|
      format.html { redirect_to_principal @principal }
      format.js
    end
  end

  def destroy
    if @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to_principal @principal }
      format.js
    end
  end

  private

  def find_principal
    principal_id = params[:user_id] || params[:group_id]
    @principal = Principal.find(principal_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_membership
    @membership = Member.find(params[:id])
    @principal = @membership.principal
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def redirect_to_principal(principal)
    redirect_to edit_polymorphic_path(principal, :tab => 'memberships')
  end
end
