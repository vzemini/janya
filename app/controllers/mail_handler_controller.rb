# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class MailHandlerController < ActionController::Base
  before_action :check_credential

  # Displays the email submission form
  def new
  end

  # Submits an incoming email to MailHandler
  def index
    options = params.dup
    email = options.delete(:email)
    if MailHandler.receive(email, options)
      head :created
    else
      head :unprocessable_entity
    end
  end

  private

  def check_credential
    User.current = nil
    unless Setting.mail_handler_api_enabled? && params[:key].to_s == Setting.mail_handler_api_key
      render :plain => 'Access denied. Incoming emails WS is disabled or key is invalid.', :status => 403
    end
  end
end
