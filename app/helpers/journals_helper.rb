# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module JournalsHelper

  # Returns the attachments of a journal that are displayed as thumbnails
  def journal_thumbnail_attachments(journal)
    ids = journal.details.select {|d| d.property == 'attachment' && d.value.present?}.map(&:prop_key)
    ids.any? ? Attachment.where(:id => ids).select(&:thumbnailable?) : []
  end

  def render_notes(issue, journal, options={})
    content = ''
    css_classes = "wiki"
    links = []
    if journal.notes.present?
      links << link_to(l(:button_quote),
                       quoted_issue_path(issue, :journal_id => journal),
                       :remote => true,
                       :method => 'post',
                       :title => l(:button_quote),
                       :class => 'icon-only icon-comment'
                      ) if options[:reply_links]

      if journal.editable_by?(User.current)
        links << link_to(l(:button_edit),
                         edit_journal_path(journal),
                         :remote => true,
                         :method => 'get',
                         :title => l(:button_edit),
                         :class => 'icon-only icon-edit'
                        )
        links << link_to(l(:button_delete),
                         journal_path(journal, :journal => {:notes => ""}),
                         :remote => true,
                         :method => 'put', :data => {:confirm => l(:text_are_you_sure)}, 
                         :title => l(:button_delete),
                         :class => 'icon-only icon-del'
                        )
        css_classes << " editable"
      end
    end
    content << content_tag('div', links.join(' ').html_safe, :class => 'contextual') unless links.empty?
    content << textilizable(journal, :notes)
    content_tag('div', content.html_safe, :id => "journal-#{journal.id}-notes", :class => css_classes)
  end

  def render_private_notes_indicator(journal)
    content = journal.private_notes? ? l(:field_is_private) : ''
    css_classes = journal.private_notes? ? 'private' : ''
    content_tag('span', content.html_safe, :id => "journal-#{journal.id}-private_notes", :class => css_classes)
  end
end
