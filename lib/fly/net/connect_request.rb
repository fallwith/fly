# frozen_string_literal: true

module Fly
  module Net
    # Fly::Net::ConnectRequest - helpers for performing a connect request
    module ConnectRequest
      module_function

      ENVIRONMENT_METADATA = 'NEW_RELIC_METADATA_'
      LABELS_MAX_COUNT = 64
      LABELS_MAX_LENGTH = 255
      LANGUAGE = 'ruby'

      def hash(security_policies) # rubocop:disable Metrics/MethodLength
        { pid: $PID,
          host: local_hostname,
          display_host: display_host,
          app_name: Fly::Config[:app_name],
          language: LANGUAGE,
          labels: labels,
          agent_version: Fly::VERSION,
          environment: environment_report,
          metadata: environment_metadata,
          settings: config_settings,
          high_security: Fly::Config[:high_security],
          utilization: utilization_data,
          identifier: "ruby:#{local_hostname}:#{Fly::Config[:app_name].sort.join(',')}",
          event_harvest_config: harvest_limits }.merge(security_policies)
      end

      def config_settings
        # TODO: dotted hash
        {}
      end

      def display_host
        Fly::Config[:'process_host.display_name'] || local_hostname
      end

      def environment_metadata
        ENV.select { |k, _v| k.start_with?(ENVIRONMENT_METADATA) }
      end

      def environment_report
        # TODO: environment report
        []
      end

      def harvest_limits
        { harvest_limits: { analytic_event_data: Fly::Config[:'transaction_events.max_samples_stored'],
                            custom_event_data: Fly::Config[:'custom_insights_events.max_samples_stored'],
                            error_event_data: Fly::Config[:'error_collector.max_event_samples_stored'],
                            log_event_data: Fly::Config[:'application_logging.forwarding.max_samples_stored'],
                            span_event_data: Fly::Config[:'span_events.max_samples_stored'] } }
      end

      def labels
        return [] if Fly::Config[:labels].to_s.empty?

        hash = labels_to_hash(Fly::Config[:labels])
        hash = labels_restrict_hash(hash)

        hash.each_with_object([]) do |(k, v), a|
          a << { 'label_type' => k, 'label_value' => v }
        end
      end

      def labels_restrict_hash(hash) # rubocop:disable Metrics/MethodLength
        restricted = {}
        hash.each_with_index do |(k, v), i|
          if (i + 1) > LABELS_MAX_COUNT
            Fly::Agent.logger.warn "Found more than #{LABELS_MAX_COUNT} labels. " \
                                   "Truncating the list to #{LABELS_MAX_COUNT}"
            break
          end
          if v.length > LABELS_MAX_LENGTH
            Fly::Agent.logger.warn "Label '#{k}' has a value over #{LABELS_MAX_LENGTH} in length and will be truncated."
            v = v[0..LABELS_MAX_LENGTH - 1]
          end
          restricted[k] = v
        end
        restricted
      end

      # allow the user to define labels as any of these in YAML (though only a
      # string from the env var):
      #   - String, ex: `'label1:value1;label2:value2'`
      #   - Array, ex: `[[label1, value1], [label2, value2]]`
      #   - Hash, ex: `{ label1 => value1, label2 => value2 }`
      # When an Array or Hash is used, labels and values can be either symbols or
      # strings.
      def labels_to_hash(labels)
        return labels if labels.is_a?(Hash)
        return labels.each_with_object({}) { |a, h| h[a[0]] = a[1] } if labels.is_a?(Array)

        labels.split(/\s*;\s*/).each_with_object({}) do |pair, h|
          k, v = pair.split(/\s*:\s*/)
          h[k] = v
        end
      end

      def local_hostname
        Socket.gethostname.force_encoding(Encoding::UTF_8)
      end

      def utilization_data
        # TODO: utilization data
        {}
      end
    end
  end
end
