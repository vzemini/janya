# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module GroupsHelper
  def group_settings_tabs(group)
    tabs = []
    tabs << {:name => 'general', :partial => 'groups/general', :label => :label_general}
    tabs << {:name => 'users', :partial => 'groups/users', :label => :label_user_plural} if group.givable?
    tabs << {:name => 'memberships', :partial => 'groups/memberships', :label => :label_project_plural}
    tabs
  end

  def render_principals_for_new_group_users(group, limit=100)
    scope = User.active.sorted.not_in_group(group).like(params[:q])
    principal_count = scope.count
    principal_pages = Janya::Pagination::Paginator.new principal_count, limit, params['page']
    principals = scope.offset(principal_pages.offset).limit(principal_pages.per_page).to_a

    s = content_tag('div',
      content_tag('div', principals_check_box_tags('user_ids[]', principals), :id => 'principals'),
      :class => 'objects-selection'
    )

    links = pagination_links_full(principal_pages, principal_count, :per_page_links => false) {|text, parameters, options|
      link_to text, autocomplete_for_user_group_path(group, parameters.merge(:q => params[:q], :format => 'js')), :remote => true
    }

    s + content_tag('span', links, :class => 'pagination')
  end
end
