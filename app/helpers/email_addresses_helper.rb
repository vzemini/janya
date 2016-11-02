# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module EmailAddressesHelper

  # Returns a link to enable or disable notifications for the address
  def toggle_email_address_notify_link(address)
    if address.notify?
      link_to l(:label_disable_notifications),
        user_email_address_path(address.user, address, :notify => '0'),
        :method => :put, :remote => true,
        :title => l(:label_disable_notifications),
        :class => 'icon-only icon-email'
    else
      link_to l(:label_enable_notifications),
        user_email_address_path(address.user, address, :notify => '1'),
        :method => :put, :remote => true,
        :title => l(:label_enable_notifications),
        :class => 'icon-only icon-email-disabled'
    end
  end
end
