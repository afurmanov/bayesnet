require "bayesnet/graph"

module Bayesnet
  module DSL
    def define(&block)
      graph = Graph.new
      graph.instance_eval(&block) if block
      graph.resolve_factors
      graph
    end
  end
end
