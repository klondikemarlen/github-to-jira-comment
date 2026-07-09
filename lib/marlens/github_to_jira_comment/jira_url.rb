# frozen_string_literal: true

require "uri"

module Marlens
  module GithubToJiraComment
    class JiraUrl
      Issue = Struct.new(:base_url, :issue_key, keyword_init: true)

      def self.parse(url)
        uri = URI.parse(url)
        match = uri.path.match(%r{\A/browse/([A-Z][A-Z0-9_]*-\d+)\z})
        unless uri.is_a?(URI::HTTPS) && uri.host&.end_with?(".atlassian.net") && match
          raise ArgumentError, "Jira URL must be https://<site>.atlassian.net/browse/<ISSUE-KEY>"
        end

        Issue.new(base_url: "#{uri.scheme}://#{uri.host}", issue_key: match[1])
      rescue URI::InvalidURIError
        raise ArgumentError, "Invalid Jira URL"
      end
    end
  end
end
