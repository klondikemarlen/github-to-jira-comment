# frozen_string_literal: true

module Marlens
  module GithubToJiraComment
    class CommentPoster
      DEFAULT_IMAGE_HOSTS = ["github.com", "private-user-images.githubusercontent.com", "user-images.githubusercontent.com"].freeze

      def initialize(jira_client:)
        @jira_client = jira_client
      end

      def post(jira_url:, markdown:, allowed_image_hosts: DEFAULT_IMAGE_HOSTS)
        create(
          issue_key: JiraUrl.parse(jira_url).issue_key,
          markdown:,
          allowed_image_hosts:
        )
      end

      def create(issue_key:, markdown:, allowed_image_hosts: [])
        hosts = (DEFAULT_IMAGE_HOSTS + allowed_image_hosts).uniq
        @jira_client.create_markdown_comment(
          issue_key:,
          markdown:,
          allowed_image_hosts: hosts,
          strict_images: true,
          image_upload_failures: []
        )
      end
    end
  end
end
