# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP�

module SearchHelper
  def highlight_tokens(text, tokens)
    return text unless text && tokens && !tokens.empty?
    re_tokens = tokens.collect {|t| Regexp.escape(t)}
    regexp = Regexp.new "(#{re_tokens.join('|')})", Regexp::IGNORECASE
    result = ''
    text.split(regexp).each_with_index do |words, i|
      if result.length > 1200
        # maximum length of the preview reached
        result << '...'
        break
      end
      if i.even?
        result << h(words.length > 100 ? "#{words.slice(0..44)} ... #{words.slice(-45..-1)}" : words)
      else
        t = (tokens.index(words.downcase) || 0) % 4
        result << content_tag('span', h(words), :class => "highlight token-#{t}")
      end
    end
    result.html_safe
  end

  def type_label(t)
    l("label_#{t.singularize}_plural", :default => t.to_s.humanize)
  end

  def project_select_tag
    options = [[l(:label_project_all), 'all']]
    options << [l(:label_my_projects), 'my_projects'] unless User.current.memberships.empty?
    options << [l(:label_and_its_subprojects, @project.name), 'subprojects'] unless @project.nil? || @project.descendants.active.empty?
    options << [@project.name, ''] unless @project.nil?
    label_tag("scope", l(:description_project_scope), :class => "hidden-for-sighted") +
    select_tag('scope', options_for_select(options, params[:scope].to_s)) if options.size > 1
  end

  def render_results_by_type(results_by_type)
    links = []
    # Sorts types by results count
    results_by_type.keys.sort {|a, b| results_by_type[b] <=> results_by_type[a]}.each do |t|
      c = results_by_type[t]
      next if c == 0
      text = "#{type_label(t)} (#{c})"
      links << link_to(h(text), :q => params[:q], :titles_only => params[:titles_only],
                       :all_words => params[:all_words], :scope => params[:scope], t => 1)
    end
    ('<ul>'.html_safe +
        links.map {|link| content_tag('li', link)}.join(' ').html_safe + 
        '</ul>'.html_safe) unless links.empty?
  end
end
