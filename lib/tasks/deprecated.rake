def deprecated_task(name, new_name)
  task name=>new_name do
    $stderr.puts "\nNote: The rake task #{name} has been deprecated, please use the replacement version #{new_name}"
  end
end

deprecated_task :load_default_data, "janya:load_default_data"
deprecated_task :migrate_from_mantis, "janya:migrate_from_mantis"
deprecated_task :migrate_from_trac, "janya:migrate_from_trac"
deprecated_task "db:migrate_plugins", "janya:plugins:migrate"
deprecated_task "db:migrate:plugin", "janya:plugins:migrate"
deprecated_task :generate_session_store, :generate_secret_token
deprecated_task "test:rdm_routing", "test:routing"
