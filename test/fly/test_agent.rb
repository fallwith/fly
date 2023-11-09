# frozen_string_literal: true

require 'test_helper'

# TestAgent = test lib/fly/agent.rb
class TestAgent < Minitest::Test
  def setup
    teardown
  end

  def teardown
    %i[@logger @net].each do |name|
      next unless Fly::Agent.instance_variable_defined?(name)

      Fly::Agent.remove_instance_variable(name)
    end
  end

  def test_agent_initializes_everything
    Fly::Agent.initialize_instances

    assert_equal %i[@logger @net], Fly::Agent.instance_variables
  end

  def test_stop_wipes_vars
    Fly::Agent.initialize_instances

    assert_equal %i[@logger @net], Fly::Agent.instance_variables
    assert Fly::Agent.instance_variable_get(:@logger)
    assert Fly::Agent.instance_variable_get(:@net)

    Fly::Agent.stop

    assert_equal %i[@logger @net], Fly::Agent.instance_variables
    refute Fly::Agent.instance_variable_get(:@logger)
    refute Fly::Agent.instance_variable_get(:@net)
  end

  # are vars are set and wiped
  def test_wipe
    logger = Minitest::Mock.new
    logger.expect :wipe, nil
    net = Minitest::Mock.new
    net.expect :wipe, nil

    Fly::Agent.instance_variable_set(:@logger, logger)
    Fly::Agent.instance_variable_set(:@net, net)
    Fly::Agent.wipe

    logger.verify
    net.verify
  end

  # one var is set but doesn't respond to wipe, and one var isn't set
  def test_wipe_checks_if_each_object_itself_responds_to_wipe
    Fly::Agent.instance_variable_set(:@logger, Object.new)
    result = Fly::Agent.wipe

    assert_equal %i[@logger @net], result
  end

  # TODO
  def test_observe
    Fly::Agent.observe do
      11 / 38
    end
  end

  # TODO
  def test_run
    Fly::Agent.run
  end

  # TODO
  def test_restart
    Fly::Agent.restart
  end
end
