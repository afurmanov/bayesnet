# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pry-byebug"
require "bayesnet"

require "minitest/autorun"

class Minitest::Test
  def load_fixture(name)
    File.read(File.expand_path("fixtures/#{name}", __dir__))
  end

  def builder
    Bayesnet::Parsers::BifParser.new
  end

  def parser
    Bayesnet::Parsers::BifParser.new
  end

  def parse(input)
    parser.parse(input)
  end

  def build(input)
    parser.build(input)
  end
end
