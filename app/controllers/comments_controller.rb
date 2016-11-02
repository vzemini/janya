# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class CommentsController < ApplicationController
  default_search_scope :news
  model_object News
  before_action :find_model_object
  before_action :find_project_from_association
  before_action :authorize

  def create
    raise Unauthorized unless @news.commentable?

    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @news.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to news_path(@news)
  end

  def destroy
    @news.comments.find(params[:comment_id]).destroy
    redirect_to news_path(@news)
  end

  private

  # ApplicationController's find_model_object sets it based on the controller
  # name so it needs to be overriden and set to @news instead
  def find_model_object
    super
    @news = @object
    @comment = nil
    @news
  end
end
