# frozen_string_literal: true

require_relative "feature_envy/version"

# Features inspired by other programming languages.
#
# Features are independent from each other and are implemented in separate
# submodules. Refer to module documentation for details on how each feature can
# be enabled and used.
module FeatureEnvy
  # A base class for all errors raised by Feature Envy.
  class Error < StandardError; end

  autoload :Internal,     "feature_envy/internal"
  autoload :FinalClass,   "feature_envy/final_class"
  autoload :LazyAccessor, "feature_envy/lazy_accessor"
end
