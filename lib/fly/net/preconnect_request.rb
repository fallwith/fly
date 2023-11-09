# frozen_string_literal: true

module Fly
  module Net
    # Fly::Net::PreconnectRequest - helpers for performing a preconnect request
    module PreconnectRequest
      module_function

      ENABLED = 'enabled'
      SECURITY_POLICY_KEYS = %w[allow_raw_exception_messages
                                attributes_include
                                custom_events
                                custom_instrumentation_editor
                                custom_parameters
                                message_parameters
                                record_sql].freeze

      def hash
        return { high_security: Fly::Config[:high_security] } unless Fly::Config[:security_policies_token]

        { security_policies_token: Fly::Config[:security_policies_token], high_security: false }
      end

      def update_security_policies(response_hash)
        policies = response_hash.fetch('security_policies', nil)
        return {} unless policies

        connect_hash = policies.transform_values { |v| { ENABLED => v[ENABLED] } }
        unless connect_hash.keys == SECURITY_POLICY_KEYS
          raise 'Security policy mismatch between New Relic server and Fly client version' \
                "#{Fly::VERSION} encountered! " \
                "\nPolicies known to the agent: #{SECURITY_POLICY_KEYS.join('|')}\n" \
                "\nPolicies known to the server: #{connect_hash.keys.join('|')}"
        end

        { 'security_policies' => connect_hash }
      end
    end
  end
end
