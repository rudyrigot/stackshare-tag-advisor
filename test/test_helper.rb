ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"

require 'webmock/minitest'

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Including the test/services folder in the tests
  Rails::TestTask.new("test:services" => "test:prepare") do |t|
    t.pattern = "test/services/**/*_test.rb"
  end
  Rake::Task["test:run"].enhance ["test:services"]
end
