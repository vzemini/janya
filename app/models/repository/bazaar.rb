# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

require 'janya/scm/adapters/bazaar_adapter'

class Repository::Bazaar < Repository
  attr_protected :root_url
  validates_presence_of :url, :log_encoding

  def self.human_attribute_name(attribute_key_name, *args)
    attr_name = attribute_key_name.to_s
    if attr_name == "url"
      attr_name = "path_to_repository"
    end
    super(attr_name, *args)
  end

  def self.scm_adapter_class
    Janya::Scm::Adapters::BazaarAdapter
  end

  def self.scm_name
    'Bazaar'
  end

  def entry(path=nil, identifier=nil)
    scm.bzr_path_encodig = log_encoding
    scm.entry(path, identifier)
  end

  def cat(path, identifier=nil)
    scm.bzr_path_encodig = log_encoding
    scm.cat(path, identifier)
  end

  def annotate(path, identifier=nil)
    scm.bzr_path_encodig = log_encoding
    scm.annotate(path, identifier)
  end

  def diff(path, rev, rev_to)
    scm.bzr_path_encodig = log_encoding
    scm.diff(path, rev, rev_to)
  end

  def scm_entries(path=nil, identifier=nil)
    scm.bzr_path_encodig = log_encoding
    entries = scm.entries(path, identifier)
    if entries
      entries.each do |e|
        next if e.lastrev.revision.blank?
        # Set the filesize unless browsing a specific revision
        if identifier.nil? && e.is_file?
          full_path = File.join(root_url, e.path)
          e.size = File.stat(full_path).size if File.file?(full_path)
        end
        c = Change.
              includes(:changeset).
              where("#{Change.table_name}.revision = ? and #{Changeset.table_name}.repository_id = ?", e.lastrev.revision, id).
              order("#{Changeset.table_name}.revision DESC").
              first
        if c
          e.lastrev.identifier = c.changeset.revision
          e.lastrev.name       = c.changeset.revision
          e.lastrev.author     = c.changeset.committer
        end
      end
    end
    entries
  end
  protected :scm_entries

  def fetch_changesets
    scm.bzr_path_encodig = log_encoding
    scm_info = scm.info
    if scm_info
      # latest revision found in database
      db_revision = latest_changeset ? latest_changeset.revision.to_i : 0
      # latest revision in the repository
      scm_revision = scm_info.lastrev.identifier.to_i
      if db_revision < scm_revision
        logger.debug "Fetching changesets for repository #{url}" if logger && logger.debug?
        identifier_from = db_revision + 1
        while (identifier_from <= scm_revision)
          # loads changesets by batches of 200
          identifier_to = [identifier_from + 199, scm_revision].min
          revisions = scm.revisions('', identifier_to, identifier_from)
          transaction do
            revisions.reverse_each do |revision|
              changeset = Changeset.create(:repository   => self,
                                           :revision     => revision.identifier,
                                           :committer    => revision.author,
                                           :committed_on => revision.time,
                                           :scmid        => revision.scmid,
                                           :comments     => revision.message)

              revision.paths.each do |change|
                Change.create(:changeset => changeset,
                              :action    => change[:action],
                              :path      => change[:path],
                              :revision  => change[:revision])
              end
            end
          end unless revisions.nil?
          identifier_from = identifier_to + 1
        end
      end
    end
  end
end
