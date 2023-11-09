# frozen_string_literal: true

module Fly
  # Fly::Agent - primary singleton entrypoint for Fly
  module Agent
    module_function

    def initialize_instances
      logger
      net
    end

    def logger
      @logger ||= Fly::Logger.new
    end

    def net
      @net ||= Fly::Net::Client.new
    end

    def observe(&block)
      initialize_instances

      # TODO: wrapper around the yield
      block.call
    end

    def run
      initialize_instances

      # TODO: loop
    end

    def stop
      @logger = nil
      @net = nil
    end

    def wipe
      %i[@logger @net].each do |name|
        next unless instance_variable_defined?(name)

        var = instance_variable_get(name)
        var.wipe if var.respond_to?(:wipe)
        remove_instance_variable(name)
      end
    end

    def restart
      wipe
      stop
      run
    end
  end
end
