# frozen_string_literal: true

require "spec_helper"

RSpec.describe Marlens::GithubToJiraComment::GithubClient do
  class RecordingGithubHttp
    attr_reader :requests

    def initialize(response)
      @response = response
      @requests = []
    end

    def get(path, headers: {})
      @requests << { path: path, headers: headers }
      @response
    end
  end

  it "fetches pull request title and body from the pulls API path" do
    http = RecordingGithubHttp.new("title" => "Fix publishing", "body" => "Pull body")
    client = described_class.new(http: http, token: "github-token")

    source = client.fetch("https://github.com/icefoganalytics/wrap/pull/405")

    expect(http.requests.map { |request| request[:path] }).to eq(["/repos/icefoganalytics/wrap/pulls/405"])
    expect(field(source, :title)).to eq("Fix publishing")
    expect(field(source, :body)).to eq("Pull body")
  end

  it "fetches issue title and body from the issues API path" do
    http = RecordingGithubHttp.new("title" => "Bug report", "body" => "Issue body")
    client = described_class.new(http: http, token: "github-token")

    source = client.fetch("https://github.com/icefoganalytics/wrap/issues/417")

    expect(http.requests.map { |request| request[:path] }).to eq(["/repos/icefoganalytics/wrap/issues/417"])
    expect(field(source, :title)).to eq("Bug report")
    expect(field(source, :body)).to eq("Issue body")
  end
end
