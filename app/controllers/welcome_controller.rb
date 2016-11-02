# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class WelcomeController < ApplicationController

  def index
    @news = News.latest User.current
  end

  def robots
    @projects = Project.all_public.active
    render :layout => false, :content_type => 'text/plain'
  end
end
