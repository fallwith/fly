# frozen_string_literal: true

require 'json'
require 'net/http'
require 'socket'
require 'zlib'
require 'English'

require_relative 'connect_request'
require_relative 'normalize'
require_relative 'preconnect_request'

module Fly
  module Net
    # Fly::Net::Client - handles sending and receiving HTTP data to and from
    #                    New Relic
    class Client
      BINARY = 'BINARY'
      CONTENT_TYPE = 'application/octet-stream'
      GZIP = 'gzip'
      IDENTITY = 'identity'
      KEEPALIVE_TIMEOUT_SECS = 60
      MAX_ATTEMPTS = 2
      # Don't perform compression on the payload unless its uncompressed size is
      # greater than or equal to this number of bytes. In testing with
      # Ruby 2.2 - 3.1, we determined an absolute minimum value for ASCII to be
      # 535 bytes to obtain at least a 10% savings in size. It is recommended
      # that this value be kept above that 535 number. It is also important to
      # consider the CPU cost involved with performing compression and to find
      # a balance between CPU cycles spent and bandwidth saved. A good
      # reasonable default here is 2048 bytes, which is a tried and true Apache
      # Tomcat default (as of v8.5.78)
      MIN_BYTE_SIZE_TO_COMPRESS = 2048
      PROTOCOL_VERSION = 17
      READ_TIMEOUT_SECS = 120
      # If any of these are raised when connecting, rescue and retry
      RESCUED_ERRORS = [::Net::OpenTimeout,
                        ::Net::ReadTimeout,
                        ::Net::WriteTimeout,
                        ::EOFError,
                        ::SystemCallError,
                        ::SocketError].freeze
      URI = '/agent_listener/invoke_raw_method?protocol_version=' \
            "#{PROTOCOL_VERSION}&license_key=#{Fly::Config[:license_key]}" \
            '&marshal_format=json&method='
      USER_AGENT = "Fly/#{Fly::VERSION} (Ruby agent team experimental)"

      def initialize
        wipe
      end

      def send_data(request)
        response = try_to_post(request)
        # TODO: handle if response.code.to_s != '200'
        hash = JSON.parse(response.body)
        hash.fetch('return_value', nil)
        # TODO: handle nil return_value
      rescue JSON::ParserError
        # TODO: handle parser error
      end

      def start_session
        security_policies = preconnect
        connect(security_policies)

        # TODO: reconfigure agent based on received server-side config
        # TODO: retry with exponential backoff
      end

      def wipe
        @agent_run_id = nil
        @host = Fly::Config[:host]
        @client = nil
        @request_headers_map = {}
      end

      private

      def create_request(method, hash = {})
        body, encoding = body_and_encoding(hash)
        request = ::Net::HTTP::Post.new("#{URI}#{method}", headers(encoding))
        request['user-agent'] = USER_AGENT
        request.content_type = CONTENT_TYPE
        request.body = body
        request
      end

      def body_and_encoding(hash)
        json = [Fly::Net::Normalize.normalize(hash)].to_json
        return [json, IDENTITY] unless json.size >= MIN_BYTE_SIZE_TO_COMPRESS

        string_io = StringIO.new
        string_io.set_encoding(BINARY)
        gw = Zlib::GzipWriter.new(string_io)
        gw.write(json)
        gw.close
        string_io.rewind

        [string_io.string, GZIP]
      end

      def client
        @client ||= begin
          c = ::Net::HTTP.new(@host, 443)
          c.use_ssl = true
          c.verify_mode = OpenSSL::SSL::VERIFY_PEER
          c.read_timeout = READ_TIMEOUT_SECS
          c.keep_alive_timeout = KEEPALIVE_TIMEOUT_SECS
          c
        end
      end

      def connect(security_policies)
        @request_headers_map = {}
        response_hash = send_data(create_request(:connect, Fly::Net::ConnectRequest.hash(security_policies)))
        @request_headers_map = response_hash['request_headers_map']
        @agent_run_id = response_hash['agent_run_id']
        response_hash.merge(security_policies)
      end

      def headers(encoding)
        { 'Content-Encoding' => encoding, 'Host' => @host }.merge(@request_headers_map).freeze
      end

      def preconnect
        response_hash = send_data(create_request(:preconnect, Fly::Net::PreconnectRequest.hash))
        redirect_host = response_hash.fetch('redirect_host', nil)
        if redirect_host && @host != redirect_host
          @host = redirect_host
          @client = nil
        end
        # returns a security policies hash to be merged with the connect process
        # request body hash
        Fly::Net::PreconnectRequest.update_security_policies(response_hash)
      end

      def try_to_post(request)
        attempt ||= 0
        attempt += 1
        client.request(request)
      rescue *RESCUED_ERRORS
        raise if attempt >= MAX_ATTEMPTS

        retry
      end
    end
  end
end
