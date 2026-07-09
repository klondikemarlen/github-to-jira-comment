# frozen_string_literal: true

require "optparse"
require "marlens/jira_api"

module Marlens
  module GithubToJiraComment
    class CLI
      def self.run(argv = ARGV, env: ENV, out: $stdout, err: $stderr, github_client_factory: nil, jira_client_factory: nil)
        new(env:, out:, err:, github_client_factory:, jira_client_factory:).call(argv)
      end

      def initialize(env: ENV, out: $stdout, err: $stderr, github_client_factory: nil, jira_client_factory: nil, markdown_resolver_factory: nil, comment_poster_factory: nil)
        @env = env
        @out = out
        @err = err
        @github_client_factory = github_client_factory
        @jira_client_factory = jira_client_factory
        @markdown_resolver_factory = markdown_resolver_factory
        @comment_poster_factory = comment_poster_factory
      end

      def call(argv)
        options = parse_options(argv.dup)
        missing = %i[github_url jira_url].select { |key| options[key].to_s.empty? }
        return fail_with("Missing required option(s): #{option_names(missing)}") unless missing.empty?

        source = github_client.fetch(options.fetch(:github_url))
        resolved = resolve_markdown(source.body, github_url: options.fetch(:github_url))
        result = post_comment(options.fetch(:jira_url), resolved)

        @out.puts(result.fetch("id") { result.fetch(:id) })
        0
      rescue ArgumentError, KeyError, OptionParser::ParseError, RuntimeError => error
        fail_with(error.message)
      end

      private

      ResolvedMarkdown = Struct.new(:markdown, :allowed_image_hosts, keyword_init: true)

      def parse_options(argv)
        options = {}
        OptionParser.new do |parser|
          parser.banner = "Usage: github-to-jira-comment --github-url URL --jira-url URL"
          parser.on("--github-url URL", "GitHub pull request or issue URL") { |value| options[:github_url] = value }
          parser.on("--jira-url URL", "Jira browse URL") { |value| options[:jira_url] = value }
        end.parse!(argv)
        options
      end

      def resolve_markdown(markdown, github_url:)
        resolver = markdown_resolver
        result = if resolver.respond_to?(:resolve_with_metadata)
                   resolver.resolve_with_metadata(markdown, context: GithubUrl.parse(github_url).context)
                 else
                   resolver.resolve(markdown)
                 end
        result.respond_to?(:markdown) ? result : ResolvedMarkdown.new(markdown: result, allowed_image_hosts: CommentPoster::DEFAULT_IMAGE_HOSTS)
      end

      def post_comment(jira_url, resolved)
        poster = comment_poster(jira_url)
        options = {
          jira_url:,
          markdown: resolved.markdown,
          allowed_image_hosts: resolved.allowed_image_hosts,
        }
        poster.post(**options)
      end

      def github_client
        @github_client ||= @github_client_factory&.call || GithubClient.new(token: @env.fetch("GITHUB_TOKEN"))
      end

      def markdown_resolver
        @markdown_resolver ||= @markdown_resolver_factory&.call || GithubMarkdownResolver.new(github_client: github_client)
      end

      def comment_poster(jira_url)
        @comment_poster ||= @comment_poster_factory&.call || CommentPoster.new(jira_client: jira_client(jira_url))
      end

      def jira_client(jira_url)
        jira_issue = JiraUrl.parse(jira_url)
        return @jira_client_factory.call(env: @env, base_url: @env["JIRA_BASE_URL"] || jira_issue.base_url) if @jira_client_factory

        Marlens::JiraApi::Client.new(
          base_url: @env["JIRA_BASE_URL"] || jira_issue.base_url,
          email: @env.fetch("JIRA_EMAIL"),
          api_token: @env.fetch("JIRA_API_TOKEN")
        )
      end

      def fail_with(message)
        @err.puts(message)
        1
      end

      def option_names(keys)
        keys.map { |key| "--#{key.to_s.tr("_", "-")}" }.join(", ")
      end
    end
  end
end
