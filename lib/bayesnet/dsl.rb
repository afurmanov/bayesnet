require "bayesnet/graph"

module Bayesnet
  module DSL
    def define(&block)
      graph = Graph.new
      graph.instance_eval(&block) if block
      graph
    end
  end
end
