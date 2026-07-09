# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Marlens
  module GithubToJiraComment
    class GithubClient
      Content = Struct.new(:title, :body, keyword_init: true)

      API_ROOT = "https://api.github.com"

      def initialize(token:, http: nil, requester: nil)
        @token = token
        @http = http
        @requester = requester || method(:request)
      end

      def fetch(source)
        source = GithubUrl.parse(source) if source.is_a?(String)
        json = get_json(source.api_path)
        Content.new(title: json.fetch("title"), body: json["body"].to_s)
      end

      def render_markdown(markdown, context:)
        uri = URI("#{API_ROOT}/markdown")
        request = Net::HTTP::Post.new(uri)
        request.body = JSON.dump("text" => markdown, "mode" => "gfm", "context" => context)
        response = perform(uri, request)
        return response.body if response.code.to_i.between?(200, 299)

        raise "GitHub Markdown render failed: #{response.code} #{response.body}"
      end

      private

      def get_json(path)
        return @http.get(path, headers:) if @http

        uri = URI("#{API_ROOT}#{path}")
        response = perform(uri, Net::HTTP::Get.new(uri))
        return JSON.parse(response.body) if response.code.to_i.between?(200, 299)

        raise "GitHub API request failed: #{response.code} #{response.body}"
      end

      def perform(uri, request)
        headers.each { |key, value| request[key] = value }
        request["Content-Type"] = "application/json" if request.request_body_permitted?
        @requester.call(uri, request)
      end

      def headers
        {
          "Accept" => "application/vnd.github+json",
          "Authorization" => "Bearer #{@token}",
        }
      end

      def request(uri, request)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end
      end
    end
  end
end
