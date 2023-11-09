# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/fly/net/preconnect_request'

# TestPreconnectRequest = test lib/fly/net/preconnect_request.rb
class TestPreconnectRequest < Minitest::Test
  def test_the_security_token_is_included_in_the_preconnect_request_hash_when_present
    token = 'the token'
    with_config security_policies_token: token do
      hash = Fly::Net::PreconnectRequest.hash

      assert_equal token, hash[:security_policies_token]
    end
  end

  def test_updates_the_security_policies_if_policies_are_seen_in_the_preconnect_response
    policies = Fly::Net::PreconnectRequest::SECURITY_POLICY_KEYS.each_with_object({}) do |k, h|
      h[k] = { 'enabled' => [true, false].sample }
    end
    response_hash = { 'security_policies' => policies }
    request_hash = Fly::Net::PreconnectRequest.update_security_policies(response_hash)

    policies.each do |k, v|
      assert_equal v['enabled'], request_hash['security_policies'][k]['enabled']
    end
  end

  def test_raises_if_the_server_and_client_have_different_security_policy_lists
    # pretend the server only knows about 1 of the policies that the client knows about
    response_hash = { 'security_policies' => { 'attributes_include' => { 'enabled' => true } } }

    error = assert_raises StandardError do
      Fly::Net::PreconnectRequest.update_security_policies(response_hash)
    end

    assert_match(/mismatch/, error.message)
  end
end
