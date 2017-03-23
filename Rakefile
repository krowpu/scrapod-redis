# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: %i(test lint)

task test: :spec

task lint: :rubocop

task fix: 'rubocop:auto_correct'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError # rubocop:disable Lint/HandleExceptions
end
