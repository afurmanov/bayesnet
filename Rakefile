# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new("regen-bif") do |t|
  `rm ./lib/bayesnet/parsers/bif.rb`
  `tt ./lib/bayesnet/parsers/bif.treetop`
end

task default: %i[test]
