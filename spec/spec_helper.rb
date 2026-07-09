# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rspec"
require "stringio"

require "marlens/github_to_jira_comment"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end

module ContractFields
  def field(object, key)
    return object.public_send(key) if object.respond_to?(key)
    return object.fetch(key) if object.respond_to?(:fetch) && object.key?(key)
    return object.fetch(key.to_s) if object.respond_to?(:fetch) && object.key?(key.to_s)

    raise KeyError, "#{object.inspect} has no #{key} field"
  end
end

RSpec.configure do |config|
  config.include ContractFields
end
