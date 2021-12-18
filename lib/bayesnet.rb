# frozen_string_literal: true

require "set"

require_relative "bayesnet/dsl"
require_relative "bayesnet/error"
require_relative "bayesnet/factor"
require_relative "bayesnet/version"

module Bayesnet
  extend Bayesnet::DSL
end
