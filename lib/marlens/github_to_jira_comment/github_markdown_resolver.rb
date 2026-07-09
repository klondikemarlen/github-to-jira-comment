# frozen_string_literal: true

require "commonmarker"
require "uri"

module Marlens
  module GithubToJiraComment
    class GithubMarkdownResolver
      Result = Struct.new(:markdown, :allowed_image_hosts, keyword_init: true)
      Image = Struct.new(:url, keyword_init: true)

      MARKDOWN_IMAGE = /!\[[^\]]*\]\(([^)\s]+)(\s+"[^"]*")?\)/
      HTML_IMAGE = /<img\b(?<attributes>[^>]+)>/i

      def initialize(github_client: nil, renderer: nil)
        @github_client = github_client
        @renderer = renderer
      end

      def resolve(markdown, context: nil)
        resolve_with_metadata(markdown, context:).markdown
      end

      def resolve_with_metadata(markdown, context: nil)
        images = image_occurrences(markdown)
        attachment_images = images.select { |image| github_user_attachment?(image.url) }
        return Result.new(markdown:, allowed_image_hosts: []) if attachment_images.empty?

        rendered_images = rendered_image_urls(render_markdown(markdown, context:)).select { |url| rendered_attachment?(url) }
        mappings = {}
        attachment_images.each_with_index do |image, index|
          rendered = rendered_images[index] || mappings[image.url]
          raise "GitHub Markdown render did not return an image for #{image.url}" unless rendered

          mappings[image.url] ||= rendered
        end

        resolved = rewrite_image_urls(markdown, mappings)
        Result.new(markdown: resolved, allowed_image_hosts: mappings.values.filter_map { |url| host(url) }.uniq)
      end

      private

      def render_markdown(markdown, context:)
        return @renderer.render(markdown) if @renderer

        @github_client.render_markdown(markdown, context:)
      end

      def image_occurrences(markdown)
        images = []
        collect_images(markdown_document(markdown), images)
        images
      end

      def rewrite_image_urls(markdown, mappings)
        fenced = false
        markdown.each_line.map do |line|
          if line.match?(/\A\s*(```|~~~)/)
            fenced = !fenced
            next line
          end
          next line if fenced

          line
            .gsub(MARKDOWN_IMAGE) { |match| mappings.key?($1) ? match.sub($1, mappings.fetch($1)) : match }
            .gsub(HTML_IMAGE) { |match| rewrite_html_image(match, mappings) }
        end.join
      end

      def rewrite_html_image(tag, mappings)
        url = html_image_url(tag)
        return tag unless mappings.key?(url)

        tag.sub(url, mappings.fetch(url))
      end

      def collect_images(node, images)
        case node.type
        when :image
          images << Image.new(url: node.url)
        when :html_inline, :html_block
          html_image_url(node.to_commonmark)&.then { |url| images << Image.new(url:) }
        end

        node.each { |child| collect_images(child, images) }
      end

      def markdown_document(markdown)
        Commonmarker.parse(
          markdown,
          options: {
            parse: { smart: true },
            extension: { autolink: true, strikethrough: true, table: true, tagfilter: false },
          }
        )
      end

      def rendered_image_urls(html)
        html.scan(HTML_IMAGE).filter_map do |match|
          parse_html_attributes(match.first)["src"]
        end
      end

      def html_image_url(html)
        match = html.match(HTML_IMAGE)
        return nil unless match

        parse_html_attributes(match[:attributes])["src"]
      end

      def parse_html_attributes(attributes)
        attributes.scan(/([a-zA-Z:-]+)=["']([^"']+)["']/).to_h
      end


      def rendered_attachment?(url)
        uri = URI.parse(url)
        uri.host == "private-user-images.githubusercontent.com" || github_user_attachment?(url)
      rescue URI::InvalidURIError
        false
      end
      def github_user_attachment?(url)
        uri = URI.parse(url)
        uri.scheme == "https" && uri.host == "github.com" && uri.path.start_with?("/user-attachments/assets/")
      rescue URI::InvalidURIError
        false
      end

      def host(url)
        URI.parse(url).host
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
