ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }
Rails.application.reload_routes!

module ActiveSupport
  class TestCase
    # One process (spaces/009): a forked worker dies on macOS the first time it touches the ONNX
    # runtime behind Embedder.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
