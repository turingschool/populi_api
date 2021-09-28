require "bundler/setup"
require "active_support/testing/time_helpers"
require "populi_api"

SPEC_PATH = __dir__

module FixtureHelpers
  def fixture_path(filename)
    File.join(SPEC_PATH, "fixtures/#{filename}").to_s
  end

  def fixture(filename)
    File.read fixture_path(filename)
  end

  def parse_xml(xml)
    FaradayMiddleware::ParseXml.new.parse(xml).with_indifferent_access
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FixtureHelpers
  config.include ActiveSupport::Testing::TimeHelpers
end
