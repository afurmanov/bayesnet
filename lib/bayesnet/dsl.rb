# frozen_string_literal: true

require "bayesnet/graph"

module Bayesnet
  # Bayesnet::DSL.define ...
  module DSL
    def define(&block)
      graph = Graph.new
      graph.instance_eval(&block) if block
      graph.resolve_factors
      graph
    end
  end
end
