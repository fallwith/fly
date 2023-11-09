# frozen_string_literal: true

require 'logger'

module Fly
  # Fly::LoggerFormatter - formatter for Fly::Logger
  class LoggerFormatter < ::Logger::Formatter
    attr_writer :hostname, :prefix

    def call(severity, timestamp, _progname, msg)
      "#{@prefix}[#{timestamp.strftime('%F %H:%M:%S %z')} #{@hostname} (#{$PID})] #{severity} : #{msg}\n"
    end
  end
end
