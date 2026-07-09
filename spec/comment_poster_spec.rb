# frozen_string_literal: true

require "spec_helper"

RSpec.describe Marlens::GithubToJiraComment::CommentPoster do
  class RecordingJiraClient
    attr_reader :comments

    def initialize
      @comments = []
    end

    def create_markdown_comment(issue_key:, markdown:, allowed_image_hosts: [], strict_images: false, **)
      @comments << {
        issue_key: issue_key,
        markdown: markdown,
        allowed_image_hosts: allowed_image_hosts,
        strict_images: strict_images
      }
      { "id" => "69213" }
    end
  end

  it "posts Markdown to the parsed Jira issue with strict image handling" do
    jira_client = RecordingJiraClient.new
    poster = described_class.new(jira_client: jira_client)

    result = poster.post(
      jira_url: "https://yg-hpw.atlassian.net/browse/WRAPX-388",
      markdown: "Resolved GitHub body"
    )

    expect(jira_client.comments).to eq([
      {
        issue_key: "WRAPX-388",
        markdown: "Resolved GitHub body",
        allowed_image_hosts: ["github.com", "private-user-images.githubusercontent.com", "user-images.githubusercontent.com"],
        strict_images: true
      }
    ])
    expect(field(result, :id)).to eq("69213")
  end

  it "keeps legacy GitHub image hosts when resolver found no attachment rewrites" do
    jira_client = RecordingJiraClient.new
    poster = described_class.new(jira_client: jira_client)

    poster.post(
      jira_url: "https://yg-hpw.atlassian.net/browse/WRAPX-388",
      markdown: "![Screenshot](https://user-images.githubusercontent.com/example.png)",
      allowed_image_hosts: []
    )

    expect(jira_client.comments.last.fetch(:allowed_image_hosts)).to eq(
      ["github.com", "private-user-images.githubusercontent.com", "user-images.githubusercontent.com"]
    )
  end
end
