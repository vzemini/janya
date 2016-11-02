# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

module MyHelper
  # Renders the blocks
  def render_blocks(blocks, user, options={})
    s = ''.html_safe

    if blocks.present?
      blocks.each do |block|
        content = render_block_content(block, user)
        if content.present?
          if options[:edit]
            close = link_to(l(:button_delete), {:action => "remove_block", :block => block}, :method => 'post', :class => "icon-only icon-close")
            content = close + content_tag('div', content, :class => 'handle')
          end

          s << content_tag('div', content, :class => "mypage-box", :id => "block-#{block}")
        end
      end
    end
    s
  end

  # Renders a single block content
  def render_block_content(block, user)
    unless Janya::MyPage.blocks.key?(block)
      Rails.logger.warn("Unknown block \"#{block}\" found in #{user.login} (id=#{user.id}) preferences")
      return
    end

    settings = user.pref.my_page_settings(block)
    begin
      render(:partial => "my/blocks/#{block}", :locals => {:user => user, :settings => settings})
    rescue ActionView::MissingTemplate
      Rails.logger.warn("Template missing for block \"#{block}\" found in #{user.login} (id=#{user.id}) preferences")
      return nil
    end
  end

  def block_select_tag(user)
    disabled = user.pref.my_page_layout.values.flatten
    options = content_tag('option')
    Janya::MyPage.block_options.each do |label, block|
      options << content_tag('option', label, :value => block, :disabled => disabled.include?(block))
    end
    select_tag('block', options, :id => "block-select")
  end

  def calendar_items(startdt, enddt)
    Issue.visible.
      where(:project_id => User.current.projects.map(&:id)).
      where("(start_date>=? and start_date<=?) or (due_date>=? and due_date<=?)", startdt, enddt, startdt, enddt).
      includes(:project, :tracker, :priority, :assigned_to).
      references(:project, :tracker, :priority, :assigned_to).
      to_a
  end

  def documents_items
    Document.visible.order("#{Document.table_name}.created_on DESC").limit(10).to_a
  end

  def issuesassignedtome_items
    Issue.visible.open.
      assigned_to(User.current).
      limit(10).
      includes(:status, :project, :tracker, :priority).
      references(:status, :project, :tracker, :priority).
      order("#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.updated_on DESC")
  end

  def issuesreportedbyme_items
    Issue.visible.open.
      where(:author_id => User.current.id).
      limit(10).
      includes(:status, :project, :tracker).
      references(:status, :project, :tracker).
      order("#{Issue.table_name}.updated_on DESC")
  end

  def issueswatched_items
    Issue.visible.open.on_active_project.watched_by(User.current.id).recently_updated.limit(10)
  end

  def news_items
    News.visible.
      where(:project_id => User.current.projects.map(&:id)).
      limit(10).
      includes(:project, :author).
      references(:project, :author).
      order("#{News.table_name}.created_on DESC").
      to_a
  end

  def timelog_items(settings)
    days = settings[:days].to_i
    days = 7 if days < 1 || days > 365

    entries = TimeEntry.
      where("#{TimeEntry.table_name}.user_id = ? AND #{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", User.current.id, User.current.today - (days - 1), User.current.today).
      joins(:activity, :project).
      references(:issue => [:tracker, :status]).
      includes(:issue => [:tracker, :status]).
      order("#{TimeEntry.table_name}.spent_on DESC, #{Project.table_name}.name ASC, #{Tracker.table_name}.position ASC, #{Issue.table_name}.id ASC").
      to_a

    return entries, days
  end
end
