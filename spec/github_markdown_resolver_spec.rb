# frozen_string_literal: true

require "spec_helper"

RSpec.describe Marlens::GithubToJiraComment::GithubMarkdownResolver do
  class RecordingMarkdownRenderer
    attr_reader :markdowns

    def initialize(html)
      @html = html
      @markdowns = []
    end

    def render(markdown)
      @markdowns << markdown
      @html
    end
  end

  it "preserves plain attachment links and fenced examples without rendering" do
    markdown = <<~MARKDOWN
      [demo.mov](https://github.com/user-attachments/assets/plain123)

      ```md
      ![not real image](https://github.com/user-attachments/assets/code123)
      ```
    MARKDOWN
    renderer = RecordingMarkdownRenderer.new("")

    resolved = described_class.new(renderer: renderer).resolve(markdown)

    expect(resolved).to eq(markdown)
    expect(renderer.markdowns).to be_empty
  end

  it "resolves Markdown and HTML attachment images through rendered GitHub image URLs" do
    markdown = <<~MARKDOWN
      ![Screenshot](https://github.com/user-attachments/assets/md123)
      <img alt="Inline" src="https://github.com/user-attachments/assets/html123">
    MARKDOWN
    renderer = RecordingMarkdownRenderer.new(<<~HTML)
      <p><img src="https://private-user-images.githubusercontent.com/md123-rendered"></p>
      <p><img src="https://private-user-images.githubusercontent.com/html123-rendered"></p>
    HTML

    resolved = described_class.new(renderer: renderer).resolve(markdown)

    expect(renderer.markdowns).to eq([markdown])
    expect(resolved).to eq(<<~MARKDOWN)
      ![Screenshot](https://private-user-images.githubusercontent.com/md123-rendered)
      <img alt="Inline" src="https://private-user-images.githubusercontent.com/html123-rendered">
    MARKDOWN
  end

  it "does not let earlier non-attachment images shift attachment resolution" do
    markdown = <<~MARKDOWN
      ![Logo](https://example.com/logo.png)
      ![Screenshot](https://github.com/user-attachments/assets/md123)
    MARKDOWN
    renderer = RecordingMarkdownRenderer.new(<<~HTML)
      <p><img src="https://example.com/logo.png"></p>
      <p><img src="https://private-user-images.githubusercontent.com/md123-rendered"></p>
    HTML

    resolved = described_class.new(renderer: renderer).resolve(markdown)

    expect(resolved).to eq(<<~MARKDOWN)
      ![Logo](https://example.com/logo.png)
      ![Screenshot](https://private-user-images.githubusercontent.com/md123-rendered)
    MARKDOWN
  end

  it "keeps a preceding private image from shifting attachment resolution" do
    markdown = <<~MARKDOWN
      ![Existing](https://private-user-images.githubusercontent.com/existing)
      ![Screenshot](https://github.com/user-attachments/assets/new123)
    MARKDOWN
    renderer = RecordingMarkdownRenderer.new(<<~HTML)
      <p><img src="https://private-user-images.githubusercontent.com/existing"></p>
      <p><img src="https://private-user-images.githubusercontent.com/new123-rendered"></p>
    HTML

    resolved = described_class.new(renderer: renderer).resolve(markdown)

    expect(resolved).to eq(<<~MARKDOWN)
      ![Existing](https://private-user-images.githubusercontent.com/existing)
      ![Screenshot](https://private-user-images.githubusercontent.com/new123-rendered)
    MARKDOWN
  end

  it "resolves a distinct attachment after duplicate occurrences" do
    markdown = <<~MARKDOWN
      ![first](https://github.com/user-attachments/assets/dup123)
      ![second](https://github.com/user-attachments/assets/dup123)
      ![third](https://github.com/user-attachments/assets/other456)
    MARKDOWN
    renderer = RecordingMarkdownRenderer.new(<<~HTML)
      <p><img src="https://private-user-images.githubusercontent.com/dup123-rendered"></p>
      <p><img src="https://private-user-images.githubusercontent.com/other456-rendered"></p>
    HTML

    resolved = described_class.new(renderer: renderer).resolve(markdown)

    expect(resolved).to eq(<<~MARKDOWN)
      ![first](https://private-user-images.githubusercontent.com/dup123-rendered)
      ![second](https://private-user-images.githubusercontent.com/dup123-rendered)
      ![third](https://private-user-images.githubusercontent.com/other456-rendered)
    MARKDOWN
  end

  it "replaces every duplicate occurrence of a resolved image URL" do
    markdown = <<~MARKDOWN
      ![first](https://github.com/user-attachments/assets/dup123)
      ![second](https://github.com/user-attachments/assets/dup123)
    MARKDOWN
    renderer = RecordingMarkdownRenderer.new(<<~HTML)
      <p><img src="https://private-user-images.githubusercontent.com/dup123-rendered"></p>
    HTML

    resolved = described_class.new(renderer: renderer).resolve(markdown)

    expect(resolved.scan("https://private-user-images.githubusercontent.com/dup123-rendered").size).to eq(2)
    expect(resolved).not_to include("https://github.com/user-attachments/assets/dup123")
  end
end
