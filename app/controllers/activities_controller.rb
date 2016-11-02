# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class ActivitiesController < ApplicationController
  menu_item :activity
  before_action :find_optional_project
  accept_rss_auth :index

  def index
    @days = Setting.activity_days_default.to_i

    if params[:from]
      begin; @date_to = params[:from].to_date + 1; rescue; end
    end

    @date_to ||= User.current.today + 1
    @date_from = @date_to - @days
    @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
    if params[:user_id].present?
      @author = User.active.find(params[:user_id])
    end

    @activity = Janya::Activity::Fetcher.new(User.current, :project => @project,
                                                             :with_subprojects => @with_subprojects,
                                                             :author => @author)
    pref = User.current.pref
    @activity.scope_select {|t| !params["show_#{t}"].nil?}
    if @activity.scope.present?
      if params[:submit].present?
        pref.activity_scope = @activity.scope
        pref.save
      end
    else
      if @author.nil?
        scope = pref.activity_scope & @activity.event_types
        @activity.scope = scope.present? ? scope : :default
      else
        @activity.scope = :all
      end
    end

    events = @activity.events(@date_from, @date_to)

    if events.empty? || stale?(:etag => [@activity.scope, @date_to, @date_from, @with_subprojects, @author, events.first, events.size, User.current, current_language])
      respond_to do |format|
        format.html {
          @events_by_day = events.group_by {|event| User.current.time_to_date(event.event_datetime)}
          render :layout => false if request.xhr?
        }
        format.atom {
          title = l(:label_activity)
          if @author
            title = @author.name
          elsif @activity.scope.size == 1
            title = l("label_#{@activity.scope.first.singularize}_plural")
          end
          render_feed(events, :title => "#{@project || Setting.app_title}: #{title}")
        }
      end
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  # TODO: refactor, duplicated in projects_controller
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
