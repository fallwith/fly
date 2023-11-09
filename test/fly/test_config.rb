# frozen_string_literal: true

require 'test_helper'

# TestConfig = test lib/fly/config.rb
class TestConfig < Minitest::Test
  def setup
    teardown
  end

  def teardown
    %i[@hash @yaml_file @yaml_hash].each do |var|
      Fly::Config.instance.remove_instance_variable(var) if Fly::Config.instance.instance_variable_defined?(var)
    end
  end

  def test_square_brackets
    refute Fly::Config[:high_security]
  end

  def test_keys
    assert_includes Fly::Config.keys, :high_security
  end

  def test_inspect
    assert Fly::Config.inspect.is_a?(String)
  end

  def test_env_hash
    key = 'NEW_RELIC_HIGH_SECURITY'
    value = 'yep'
    ENV[key] = value

    assert_equal value, Fly::Config[:high_security]
  ensure
    ENV.delete(key)
  end

  def test_env_hash_keys_are_ignored_if_bogus
    key = 'NEW_RELIC_HI_SECURITY'
    ENV[key] = 'yep'

    refute Fly::Config[:hi_security]
  ensure
    ENV.delete(key)
  end

  def test_yaml_hash_is_empty_if_file_is_absent
    File.stub :exist?, false, 'newrelic.yml' do
      assert_empty Fly::Config.instance.send(:yaml_hash)
    end
  end

  def test_yaml_hash_is_valid
    hash = { hugh: :laurie }
    file = 'newrelic.yml'
    File.stub :exist?, true, file do
      YAML.stub :load_file, hash, file do
        assert_equal hash, Fly::Config.instance.send(:yaml_hash)
      end
    end
  end
end
