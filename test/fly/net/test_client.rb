# frozen_string_literal: true

require 'test_helper'

# TestClient = test lib/fly/net/client.rb
class TestClient < Minitest::Test
  AGENT_RUN_ID = 'the agent run id'
  REDIRECT_HOST = 'the redirect host'

  def test_client_connecting
    net = Fly::Net::Client.new
    net.instance_variable_set(:@client, phony_net_http_client)
    net.start_session

    assert_equal AGENT_RUN_ID, net.instance_variable_get(:@agent_run_id)
  end

  def test_request_bodies_are_compressed_when_large_enough
    hash = {}
    1.upto(Fly::Net::Client::MIN_BYTE_SIZE_TO_COMPRESS) do |i|
      hash[i.to_s] = 'z'
    end
    net = Fly::Net::Client.new
    body, encoding = net.send(:body_and_encoding, hash)

    assert_equal Fly::Net::Client::GZIP, encoding
    assert_equal [hash], JSON.parse(Zlib::GzipReader.new(StringIO.new(body)).read)
  end

  def test_instantiates_a_net_http_client
    net = Fly::Net::Client.new
    client = net.send(:client)

    assert_match(/#{net.instance_variable_get(:@host)}/, client.inspect)
  end

  def test_try_to_post_retries
    client = Object.new
    def client.request(_req); raise ::Net::ReadTimeout; end
    net = Fly::Net::Client.new
    net.instance_variable_set(:@client, client)

    assert_raises ::Net::ReadTimeout do
      net.send(:try_to_post, nil)
    end
  end

  def test_respects_the_servers_redirect_host_if_it_appears_in_the_preconnect_response
    net = Fly::Net::Client.new
    def net.send_data(_request); { 'redirect_host' => TestClient::REDIRECT_HOST }; end
    net.send(:preconnect)

    assert_equal TestClient::REDIRECT_HOST, net.instance_variable_get(:@host)
    refute net.instance_variable_get(:@client)
  end

  private

  def fake_response(hash)
    response.body = hash.to_json
    response
  end

  def phony_net_http_client
    @phony_net_http_client ||= begin
      client = Object.new
      def client.request(request)
        socket = Object.new
        def socket.closed?; false; end
        response = Net::HTTPResponse.new(1.1, 200, '')
        response.instance_variable_set(:@socket, socket)
        if request.body.size < 50 # preconnect
          def response.body
            { 'return_value' => {} }.to_json
          end
        else # connect
          def response.body
            { 'return_value' => { 'agent_run_id' => TestClient::AGENT_RUN_ID } }.to_json
          end
        end
        response
      end
      client
    end
  end
end
