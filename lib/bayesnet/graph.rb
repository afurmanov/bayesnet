# frozen_string_literal: true

require "bayesnet/node"

module Bayesnet
  # Acyclic graph
  class Graph
    attr_reader :nodes

    def initialize
      @nodes = {}
    end

    def var_names
      nodes.keys
    end

    def node(name, parents: [], &block)
      raise Error, "DSL error, #node requires a &block" unless block

      node = Node.new(name, parents)
      node.instance_eval(&block)
      @nodes[name] = node
    end

    def resolve_factors
      @nodes.values.each do |node|
        node.resolve_factor(@nodes.slice(*node.parent_nodes))
      end
    end

    def distribution(over: [], evidence: {})
      joint_distribution
        .reduce_to(evidence)
        .marginalize(over)
        .normalize
    end

    # This is MAP query, i.e. Maximum a Posteriory
    def most_likely_value(var_name, evidence:)
      posterior_distribution = distribution(over: [var_name], evidence: evidence)
      mode = posterior_distribution.contextes(var_name).zip(posterior_distribution.values).max_by(&:last)
      mode.first.first
    end

    def chances(assignment, evidence:)
      over_vars = assignment.slice(*var_names) # maintains order of vars
      posterior_distribution = distribution(over: over_vars.keys, evidence: evidence)
      posterior_distribution[*over_vars.values]
    end

    def joint_distribution
      return @joint_distribution if @joint_distribution

      if @nodes.empty?
        @joint_distribution = Factor.new
        return @joint_distribution
      end

      factor = Factor.new
      @nodes.each do |node_name, node|
        factor.scope node_name => node.values
      end

      factor.contextes(*var_names).each do |context|
        val_by_name = var_names.zip(context).to_h
        val = nodes.values.reduce(1.0) do |prob, node|
          prob * node.factor[val_by_name]
        end
        factor.val context + [val]
      end
      @joint_distribution = factor.normalize
    end

    def parameters
      nodes.values.map(&:parameters).sum
    end
  end
end
