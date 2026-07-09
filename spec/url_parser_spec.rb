# frozen_string_literal: true

require "spec_helper"

RSpec.describe Marlens::GithubToJiraComment::GithubUrl do
  it "parses a full pull request URL" do
    parsed = described_class.parse("https://github.com/icefoganalytics/wrap/pull/405")

    expect(field(parsed, :owner)).to eq("icefoganalytics")
    expect(field(parsed, :repo)).to eq("wrap")
    expect(field(parsed, :type)).to eq("pull")
    expect(field(parsed, :number).to_s).to eq("405")
  end

  it "parses a full issue URL" do
    parsed = described_class.parse("https://github.com/icefoganalytics/wrap/issues/417")

    expect(field(parsed, :owner)).to eq("icefoganalytics")
    expect(field(parsed, :repo)).to eq("wrap")
    expect(field(parsed, :type).to_s).to match(/\Aissues?\z/)
    expect(field(parsed, :number).to_s).to eq("417")
  end

  it "rejects shorthand references" do
    expect { described_class.parse("icefoganalytics/wrap#405") }.to raise_error(ArgumentError, /GitHub URL/i)
  end
end

RSpec.describe Marlens::GithubToJiraComment::JiraUrl do
  it "parses a full Jira browse URL" do
    parsed = described_class.parse("https://yg-hpw.atlassian.net/browse/WRAPX-388")

    expect(field(parsed, :base_url)).to eq("https://yg-hpw.atlassian.net")
    expect(field(parsed, :issue_key)).to eq("WRAPX-388")
  end

  it "rejects bare issue keys" do
    expect { described_class.parse("WRAPX-388") }.to raise_error(ArgumentError, /Jira URL/i)
  end
end
