# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module AttachmentsHelper

  def container_attachments_edit_path(container)
    object_attachments_edit_path container.class.name.underscore.pluralize, container.id
  end

  def container_attachments_path(container)
    object_attachments_path container.class.name.underscore.pluralize, container.id
  end

  # Displays view/delete links to the attachments of the given object
  # Options:
  #   :author -- author names are not displayed if set to false
  #   :thumbails -- display thumbnails if enabled in settings
  def link_to_attachments(container, options = {})
    options.assert_valid_keys(:author, :thumbnails)

    attachments = container.attachments.preload(:author).to_a
    if attachments.any?
      options = {
        :editable => container.attachments_editable?,
        :deletable => container.attachments_deletable?,
        :author => true
      }.merge(options)
      render :partial => 'attachments/links',
        :locals => {
          :container => container,
          :attachments => attachments,
          :options => options,
          :thumbnails => (options[:thumbnails] && Setting.thumbnails_enabled?)
        }
    end
  end

  def render_api_attachment(attachment, api)
    api.attachment do
      api.id attachment.id
      api.filename attachment.filename
      api.filesize attachment.filesize
      api.content_type attachment.content_type
      api.description attachment.description
      api.content_url download_named_attachment_url(attachment, attachment.filename)
      if attachment.thumbnailable?
        api.thumbnail_url thumbnail_url(attachment)
      end
      api.author(:id => attachment.author.id, :name => attachment.author.name) if attachment.author
      api.created_on attachment.created_on
    end
  end
end
