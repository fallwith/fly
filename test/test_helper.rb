# frozen_string_literal: true

require 'simplecov' unless ENV['NOCOV']

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'fly'

require 'minitest/autorun'

def with_config(hash, &block)
  Fly::Config.stub :[], proc { |k| hash.key?(k) ? hash[k] : Fly::Config.instance.send(:hash)[k] } do
    block.call
  end
end
