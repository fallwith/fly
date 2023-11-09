# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'socket'

require_relative 'logger_formatter'

module Fly
  # Fly::Logger - for Fly's own logging related duties (not observed
  #               application logging)
  class Logger < ::Logger
    DEFAULT_LEVEL = ::Logger::INFO
    MIN_LOG_LEVEL = ::Logger::DEBUG
    MAX_LOG_LEVEL = ::Logger::FATAL
    STDOUT_STRING = 'STDOUT'
    STDOUT_PATH = "<#{STDOUT_STRING}>"

    def initialize(*_args, **_kwargs)
      mkdir_p_directory
      super(target, level)
      @formatter = log_formatter
    end

    def wipe
      @target = nil
      close
    end

    private

    def hostname
      @hostname = Fly::Config[:'process_host.display_name'] || Socket.gethostname.force_encoding(Encoding::UTF_8)
    end

    def log_formatter
      formatter = Fly::LoggerFormatter.new
      formatter.hostname = hostname
      formatter.prefix = '** [NewRelic]' if want_stdout?
      formatter
    end

    def mkdir_p_directory
      return if want_stdout?

      # Technically both the :log_file_path and :log_file_name options can
      # contain path info, so smoosh them together into a full path and then
      # derive the dir path from the result.
      FileUtils.mkdir_p(File.dirname(target))
    end

    def target
      return $stdout if want_stdout?

      @target ||= File.join(Fly::Config[:log_file_path], Fly::Config[:log_file_name])
    end

    # The :log_level configuration option can be set equal to either the Integer
    # (example: `1`) or String (example: `'INFO'`) representation of a
    # `::Logger` log level
    def level
      configured = integer_configured || string_configured
      return configured if configured

      puts "Invalid Fly log level value of '#{Fly::Config[:log_level]}' configured via the :log_level option.",
           "Using a default log level (integer value = '#{DEFAULT_LEVEL}') instead."

      DEFAULT_LEVEL
    end

    def integer_configured
      level = Fly::Config[:log_level]
      level if level.is_a?(Integer) && level.between?(MIN_LOG_LEVEL, MAX_LOG_LEVEL)
    end

    def string_configured
      Logger.const_get(Fly::Config[:log_level]) if Logger.const_defined?(Fly::Config[:log_level])
    end

    # The :log_file_path configuration option can be set to `'STDOUT'`,
    # `STDOUT`, or `$stdout` to configure the logger to write to STDOUT
    def want_stdout?
      return @want_stdout if defined?(@want_stdout)

      @want_stdout ||= begin
        path = Fly::Config[:log_file_path]
        (path.is_a?(String) && path.eql?(STDOUT_STRING)) ||
          (path.respond_to?(:to_path) && path.to_path.equal(STDOUT_path))
      end
    end
  end
end
