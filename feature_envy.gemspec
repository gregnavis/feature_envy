# frozen_string_literal: true

require_relative "lib/feature_envy/version"

Gem::Specification.new do |spec|
  spec.name     = "feature_envy"
  spec.version  = FeatureEnvy::VERSION
  spec.author   = "Greg Navis"
  spec.email    = "contact@gregnavis.com"
  spec.summary  = "Feature Envy enhances Ruby with features inspired by other programming languages"
  spec.homepage = "https://github.com/gregnavis/feature_envy"
  spec.license  = "MIT"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir["lib/**/*", "MIT-LICENSE.txt", "README.md"]
  spec.test_files = Dir["test/**/*"]

  spec.require_paths = ["lib"]

  # Build
  spec.add_development_dependency "rake", "~> 13.0.6"

  # Test Suite
  spec.add_development_dependency "minitest", "~> 5.18.0"

  # Linting
  spec.add_development_dependency "rubocop", "~> 1.21.0"
  spec.add_development_dependency "rubocop-minitest", "~> 0.26.1"
  spec.add_development_dependency "rubocop-rake", "~> 0.6.0"

  # Documentation
  spec.add_development_dependency "yard", "~> 0.9.28"
end
