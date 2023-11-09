# frozen_string_literal: true

require 'singleton'
require 'yaml'

module Fly
  # Fly::Config - singleton class that behaves like a hash and holds
  #               configuration
  class Config
    include Singleton

    YAML_PATHS = [ENV.fetch('NEW_RELIC_CONFIG_PATH', nil),
                  'config/newrelic.yml',
                  'newrelic.yml',
                  "#{Dir.home}/.newrelic/newrelic.yml"].compact.freeze

    def self.[](key)
      instance[key]
    end

    def self.inspect
      instance.inspect
    end

    def self.keys
      instance.keys
    end

    def [](key)
      hash[key]
    end

    def inspect
      hash.inspect
    end

    def keys
      hash.keys
    end

    private

    def default_hash # rubocop:disable Metrics/MethodLength
      # TODO: defaults_source.rb type functionality
      { app_name: ["#{ENV.fetch('USER')}'s Test App"],
        'application_logging.forwarding.max_samples_stored': 10_000,
        'custom_insights_events.max_samples_stored': 3000,
        'error_collector.max_event_samples_stored': 100,
        high_security: false,
        host: 'collector.newrelic.com',
        'process_host.display_name': nil,
        labels: nil,
        license_key: nil,
        log_file_name: 'newrelic_fly.log',
        log_file_path: 'log',
        log_level: 'INFO',
        security_policies_token: nil,
        'span_events.max_samples_stored': 2000,
        'transaction_events.max_samples_stored': 1200 }.freeze
    end

    def env_hash
      ENV.each_with_object({}) do |(k, v), h|
        h[Regexp.last_match(1).downcase] = v if k =~ /^NEW_RELIC_([a-zA-Z0-9_]+)$/
      end
    end

    def hash
      @hash ||= prep_hash
    end

    def prep_hash
      # TODO: default_source.rb style type casting
      [yaml_hash, env_hash].each_with_object(default_hash.dup) do |h, merged|
        h.each { |k, v| merged[k.to_sym] = v if merged.key?(k.to_sym) }
      end
    end

    def yaml_file
      return @yaml_file if defined?(@yaml_file)

      @yaml_file = YAML_PATHS.detect { |f| File.exist?(f) }
    end

    def yaml_hash
      return {} unless yaml_file

      YAML.load_file(yaml_file)
    end
  end
end
