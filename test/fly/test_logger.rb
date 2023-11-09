# frozen_string_literal: true

require 'fileutils'
require 'test_helper'

# TestLogger = test lib/fly/logger.rb
class TestLogger < Minitest::Test
  def setup
    @log_file = 'log/newrelic_fly.log'
  end

  def teardown
    FileUtils.rm_f @log_file
  end

  def test_it_works_as_a_logger_ought_to
    message = 'Hello, World!'
    Fly::Logger.new.warn message

    assert_match(/#{message}/, File.read(@log_file))
  end

  def test_wipe
    l = Fly::Logger.new

    assert l.instance_variable_get(:@target)
    l.wipe

    refute l.instance_variable_get(:@target)
  end

  def test_stdout_mode
    with_config log_file_path: 'STDOUT' do
      l = Fly::Logger.new

      assert l.send(:want_stdout?)
      l.debug 'Hello!'
    end
  end

  def test_invalid_level
    with_config log_level: 'BOGUS' do
      assert_output(/Invalid Fly log level/) do
        l = Fly::Logger.new

        assert_equal Fly::Logger::DEFAULT_LEVEL, l.send(:level)
      end
    end
  end

  def test_level_can_be_numeric
    with_config log_level: 0 do
      l = Fly::Logger.new

      assert_equal ::Logger::DEBUG, l.send(:level)
    end
  end
end
