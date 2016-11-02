# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module PrincipalMembershipsHelper
  def render_principal_memberships(principal)
    render :partial => 'principal_memberships/index', :locals => {:principal => principal}
  end

  def call_table_header_hook(principal)
    if principal.is_a?(Group)
      call_hook :view_groups_memberships_table_header, :group => principal
    else
      call_hook :view_users_memberships_table_header, :user => principal
    end
  end

  def call_table_row_hook(principal, membership)
    if principal.is_a?(Group)
      call_hook :view_groups_memberships_table_row, :group => principal, :membership => membership
    else
      call_hook :view_users_memberships_table_row, :user => principal, :membership => membership
    end
  end

  def new_principal_membership_path(principal, *args)
    if principal.is_a?(Group)
      new_group_membership_path(principal, *args)
    else
      new_user_membership_path(principal, *args)
    end
  end

  def principal_membership_path(principal, membership, *args)
    if principal.is_a?(Group)
      group_membership_path(principal, membership, *args)
    else
      user_membership_path(principal, membership, *args)
    end
  end
end
