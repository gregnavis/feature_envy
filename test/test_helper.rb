# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "feature_envy"

require "minitest/autorun"

require_relative "support/assertions"

class Minitest::Test
  include Assertions
end
