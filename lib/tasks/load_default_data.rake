desc 'Load Janya default configuration data. Language is chosen interactively or by setting JANYA_LANG environment variable.'

namespace :janya do
  task :load_default_data => :environment do
    require 'custom_field'
    include Janya::I18n
    set_language_if_valid('en')

    envlang = ENV['JANYA_LANG']
    if !envlang || !set_language_if_valid(envlang)
      puts
      while true
        print "Select language: "
        print valid_languages.collect(&:to_s).sort.join(", ")
        print " [#{current_language}] "
        STDOUT.flush
        lang = STDIN.gets.chomp!
        break if lang.empty?
        break if set_language_if_valid(lang)
        puts "Unknown language!"
      end
      STDOUT.flush
      puts "===================================="
    end

    begin
      Janya::DefaultData::Loader.load(current_language)
      puts "Default configuration data loaded."
    rescue Janya::DefaultData::DataAlreadyLoaded => error
      puts error.message
    rescue => error
      puts "Error: " + error.message
      puts "Default configuration data was not loaded."
    end
  end
end
