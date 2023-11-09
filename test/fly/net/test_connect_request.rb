# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/fly/net/connect_request'

# TestConnectRequest = test lib/fly/net/connect_request.rb
class TestConnectRequest < Minitest::Test
  LABELS_REQUEST_ARRAY = [{ 'label_type' => 'key1', 'label_value' => 'value1' },
                          { 'label_type' => 'key2', 'label_value' => 'value2' }].freeze

  def test_user_defined_labels_are_included_when_config_uses_a_hash
    with_config labels: { 'key1' => 'value1', 'key2' => 'value2' }.freeze do
      hash = Fly::Net::ConnectRequest.hash({})

      assert_equal LABELS_REQUEST_ARRAY, hash[:labels]
    end
  end

  def test_user_defined_labels_are_included_when_config_uses_an_array
    with_config labels: [%w[key1 value1], %w[key2 value2]].freeze do
      hash = Fly::Net::ConnectRequest.hash({})

      assert_equal LABELS_REQUEST_ARRAY, hash[:labels]
    end
  end

  def test_user_defined_labels_are_included_when_config_uses_a_string
    with_config labels: 'key1:value1;key2:value2' do
      hash = Fly::Net::ConnectRequest.hash({})

      assert_equal LABELS_REQUEST_ARRAY, hash[:labels]
    end
  end

  def test_a_max_number_of_labels_is_enforced
    labels = (1..(Fly::Net::ConnectRequest::LABELS_MAX_COUNT + 10)).to_a.each_with_object({}) do |i, h|
      h[i.to_s] = i.to_s
    end
    with_config labels: labels do
      hash = Fly::Net::ConnectRequest.hash({})

      assert_equal Fly::Net::ConnectRequest::LABELS_MAX_COUNT, hash[:labels].size
    end
  end

  def test_label_values_are_truncated_when_too_long
    long = 'x' * (Fly::Net::ConnectRequest::LABELS_MAX_LENGTH + 10)
    with_config labels: "key1:#{long}" do
      hash = Fly::Net::ConnectRequest.hash({})
      labels = hash[:labels]

      assert_equal 1, labels.size
      assert_equal Fly::Net::ConnectRequest::LABELS_MAX_LENGTH, labels.first['label_value'].size
    end
  end
end
