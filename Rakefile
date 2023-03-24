# frozen_string_literal: true

# Gem

require "bundler/gem_tasks"

# YARD

require "yard"

YARD::Rake::YardocTask.new do |t|
  t.options       = %w[]
  t.stats_options = %w[]
end

# Tests

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

# Rubocop

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Default

task default: %i[test rubocop]
