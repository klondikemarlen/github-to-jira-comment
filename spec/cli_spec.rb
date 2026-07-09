# frozen_string_literal: true

require "spec_helper"

RSpec.describe Marlens::GithubToJiraComment::CLI do
  Source = Struct.new(:title, :body)

  class FakeCliGithubClient
    attr_reader :urls

    def initialize(source)
      @source = source
      @urls = []
    end

    def fetch(url)
      @urls << url
      @source
    end
  end

  class FakeCliResolver
    attr_reader :markdowns

    def initialize(resolved)
      @resolved = resolved
      @markdowns = []
    end

    def resolve(markdown)
      @markdowns << markdown
      @resolved
    end
  end

  class FakeCliPoster
    attr_reader :comments

    def initialize(comment_id)
      @comment_id = comment_id
      @comments = []
    end

    def post(jira_url:, markdown:, **)
      @comments << { jira_url: jira_url, markdown: markdown }
      { id: @comment_id }
    end
  end

  it "fetches, resolves, posts, and prints the created comment id" do
    github_url = "https://github.com/icefoganalytics/wrap/pull/405"
    jira_url = "https://yg-hpw.atlassian.net/browse/WRAPX-388"
    github_client = FakeCliGithubClient.new(Source.new("Fix publishing", "GitHub body"))
    resolver = FakeCliResolver.new("Resolved GitHub body")
    poster = FakeCliPoster.new("69213")
    output = StringIO.new

    described_class.new(
      github_client_factory: -> { github_client },
      markdown_resolver_factory: -> { resolver },
      comment_poster_factory: -> { poster },
      out: output
    ).call(["--github-url", github_url, "--jira-url", jira_url])

    expect(github_client.urls).to eq([github_url])
    expect(resolver.markdowns).to eq(["GitHub body"])
    expect(poster.comments).to eq([{ jira_url: jira_url, markdown: "Resolved GitHub body" }])
    expect(output.string).to eq("69213\n")
  end

  it "passes GitHub context metadata and resolved image hosts on the real resolver path" do
    github_url = "https://github.com/icefoganalytics/wrap/pull/405"
    jira_url = "https://yg-hpw.atlassian.net/browse/WRAPX-388"
    github_client = FakeCliGithubClient.new(Source.new("Fix publishing", "GitHub body"))
    output = StringIO.new

    resolver = Class.new do
      attr_reader :calls

      def initialize
        @calls = []
      end

      def resolve_with_metadata(markdown, context:)
        @calls << { markdown: markdown, context: context }
        Marlens::GithubToJiraComment::CLI.const_get(:ResolvedMarkdown).new(
          markdown: "Resolved GitHub body",
          allowed_image_hosts: ["private-user-images.githubusercontent.com"]
        )
      end
    end.new

    poster = Class.new do
      attr_reader :comments

      def initialize
        @comments = []
      end

      def post(jira_url:, markdown:, allowed_image_hosts:)
        @comments << { jira_url: jira_url, markdown: markdown, allowed_image_hosts: allowed_image_hosts }
        { "id" => "69213" }
      end
    end.new

    described_class.new(
      github_client_factory: -> { github_client },
      markdown_resolver_factory: -> { resolver },
      comment_poster_factory: -> { poster },
      out: output
    ).call(["--github-url", github_url, "--jira-url", jira_url])

    expect(resolver.calls).to eq([{ markdown: "GitHub body", context: "icefoganalytics/wrap" }])
    expect(poster.comments).to eq([
      {
        jira_url: jira_url,
        markdown: "Resolved GitHub body",
        allowed_image_hosts: ["private-user-images.githubusercontent.com"]
      }
    ])
    expect(output.string).to eq("69213\n")
  end
end
