I18n.default_locale = 'en'
I18n.backend = Janya::I18n::Backend.new
# Forces I18n to load available locales from the backend
I18n.config.available_locales = nil

require 'janya'

# Load the secret token from the Janya configuration file
secret = Janya::Configuration['secret_token']
if secret.present?
  JanyaApp::Application.config.secret_token = secret
end

if Object.const_defined?(:OpenIdAuthentication)
  openid_authentication_store = Janya::Configuration['openid_authentication_store']
  OpenIdAuthentication.store =
    openid_authentication_store.present? ?
      openid_authentication_store : :memory
end

Janya::Plugin.load
unless Janya::Configuration['mirror_plugins_assets_on_startup'] == false
  Janya::Plugin.mirror_assets
end

Rails.application.config.to_prepare do
  Janya::FieldFormat::RecordList.subclasses.each do |klass|
    klass.instance.reset_target_class
  end
end
