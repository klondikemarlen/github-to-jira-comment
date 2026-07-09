# frozen_string_literal: true

require "uri"

module Marlens
  module GithubToJiraComment
    class GithubUrl
      Source = Struct.new(:owner, :repo, :type, :number, keyword_init: true) do
        def api_path
          collection = type == "pull" ? "pulls" : "issues"
          "/repos/#{owner}/#{repo}/#{collection}/#{number}"
        end

        def context
          "#{owner}/#{repo}"
        end
      end

      def self.parse(url)
        uri = URI.parse(url)
        segments = uri.path.split("/").reject(&:empty?)
        unless uri.is_a?(URI::HTTPS) && uri.host == "github.com" && segments.length == 4
          raise ArgumentError, "GitHub URL must be https://github.com/<owner>/<repo>/pull/<number> or /issues/<number>"
        end

        owner, repo, path_type, number = segments
        unless %w[pull issues].include?(path_type) && number.match?(/\A\d+\z/)
          raise ArgumentError, "GitHub URL must point to a pull request or issue number"
        end

        Source.new(owner:, repo:, type: path_type == "pull" ? "pull" : "issue", number:)
      rescue URI::InvalidURIError
        raise ArgumentError, "Invalid GitHub URL"
      end
    end
  end
end
