# frozen_string_literal: true

# :nocov:
module Fly
  # Fly::Metric - models performance related information (call count, call time,
  #               etc.) in aggregate
  class Metric
    # submitted data may be nil, a partial data hash, or a complete data hash
    def initialize(submitted = nil)
      @lock = Mutex.new
      merge!(submitted) if submitted
    end

    def wipe
      @data = nil
    end

    def merge!(submitted)
      @lock.synchronize do
        data.each_key do |key|
          value = submitted[key]
          next unless value

          data[key] = value
        end
      end
    end

    private

    def data
      @data ||= {
        call_count: 0,
        total_call_time: 0.0,
        total_exclusive_time: 0.0,
        min_call_time: 0.0,
        max_call_time: 0.0,
        sum_of_squares: 0.0
      }
    end
  end
end
# :nocov:
