# frozen_string_literal: true

require 'test_helper'

# TestFly = test lib/fly.rb
class TestFly < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Fly::VERSION
  end
end
