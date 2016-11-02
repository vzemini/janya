# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

# Generic exception for when the AuthSource can not be reached
# (eg. can not connect to the LDAP)
class AuthSourceException < Exception; end
class AuthSourceTimeoutException < AuthSourceException; end

class AuthSource < ActiveRecord::Base
  include Janya::SafeAttributes
  include Janya::SubclassFactory
  include Janya::Ciphering

  has_many :users

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 60
  attr_protected :id

  safe_attributes 'name',
    'host',
    'port',
    'account',
    'account_password',
    'base_dn',
    'attr_login',
    'attr_firstname',
    'attr_lastname',
    'attr_mail',
    'onthefly_register',
    'tls',
    'filter',
    'timeout'

  def authenticate(login, password)
  end

  def test_connection
  end

  def auth_method_name
    "Abstract"
  end

  def account_password
    read_ciphered_attribute(:account_password)
  end

  def account_password=(arg)
    write_ciphered_attribute(:account_password, arg)
  end

  def searchable?
    false
  end

  def self.search(q)
    results = []
    AuthSource.all.each do |source|
      begin
        if source.searchable?
          results += source.search(q)
        end
      rescue AuthSourceException => e
        logger.error "Error while searching users in #{source.name}: #{e.message}"
      end
    end
    results
  end

  def allow_password_changes?
    self.class.allow_password_changes?
  end

  # Does this auth source backend allow password changes?
  def self.allow_password_changes?
    false
  end

  # Try to authenticate a user not yet registered against available sources
  def self.authenticate(login, password)
    AuthSource.where(:onthefly_register => true).each do |source|
      begin
        logger.debug "Authenticating '#{login}' against '#{source.name}'" if logger && logger.debug?
        attrs = source.authenticate(login, password)
      rescue => e
        logger.error "Error during authentication: #{e.message}"
        attrs = nil
      end
      return attrs if attrs
    end
    return nil
  end
end
