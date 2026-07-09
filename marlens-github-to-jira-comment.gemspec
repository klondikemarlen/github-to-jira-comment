# frozen_string_literal: true

require_relative "lib/marlens/github_to_jira_comment/version"

Gem::Specification.new do |spec|
  spec.name = "marlens-github-to-jira-comment"
  spec.version = Marlens::GithubToJiraComment::VERSION
  spec.authors = ["Marlen Brunner"]
  spec.email = ["klondike.marlen@gmail.com"]

  spec.summary = "Copy GitHub issue or pull request bodies into Jira comments."
  spec.description = "Small CLI/gem bridge from full GitHub issue/pull request URLs to full Jira issue URLs."
  spec.homepage = "https://github.com/klondikemarlen/github-to-jira-comment"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "marlens-jira-api", "~> 0.5"
  spec.add_dependency "commonmarker", "~> 2.8"

  spec.add_development_dependency "rspec", "~> 3.13"
end
