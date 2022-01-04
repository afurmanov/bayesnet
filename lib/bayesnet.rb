# frozen_string_literal: true

require "set"

# net
require_relative "bayesnet/dsl"
require_relative "bayesnet/error"
require_relative "bayesnet/factor"
require_relative "bayesnet/version"

# parsing
require_relative "bayesnet/parsers/builder"
require_relative "bayesnet/parsers/bif"

module Bayesnet
  extend Bayesnet::DSL
end
