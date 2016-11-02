# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CalendarsController < ApplicationController
  menu_item :calendar
  before_action :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper

  def show
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= User.current.today.year
    @month ||= User.current.today.month

    @calendar = Janya::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query
    @query.group_by = nil
    if @query.valid?
      events = []
      events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                              )
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])

      @calendar.events = events
    end

    render :action => 'show', :layout => false if request.xhr?
  end
end
