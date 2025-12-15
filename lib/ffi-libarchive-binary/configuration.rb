# frozen_string_literal: true

require "psych"
require "yaml"

module LibarchiveBinary
  def self.libraries
    configuration_file = File.join(File.dirname(__FILE__), "..", "..", "ext", "configuration.yml")
    @@libraries ||= ::YAML.load_file(configuration_file)["libraries"] || {}
  rescue Psych::SyntaxError => e
    puts "Warning: The configuration file '#{configuration_file}' contains invalid YAML syntax."
    puts e.message
    exit 1
  rescue StandardError => e
    puts "An unexpected error occurred while loading the configuration file '#{configuration_file}'."
    puts e.message
    exit 1
  end

  def self.library_for(libname)
    if MiniPortile::windows?
      # Detect Windows ARM64
      if RUBY_PLATFORM =~ /aarch64|arm64/i
        libraries[libname]["windows-arm64"] || libraries[libname]["windows"] || libraries[libname]["all"]
      else
        libraries[libname]["windows-x64"] || libraries[libname]["windows"] || libraries[libname]["all"]
      end
    else
      libraries[libname]["all"]
    end
  rescue StandardError => e
    puts "Failed to load library configuration for '#{libname}'."
    puts e.message
    exit 1
  end
end
