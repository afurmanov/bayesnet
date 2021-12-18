require "bayesnet/node"

module Bayesnet
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
      node = Node.new(name, @nodes.slice(*parents))
      node.instance_eval(&block)
      @nodes[name] = node
    end

    def distribution(over: [], evidence: {})
      limited = joint_distribution.limit_by(evidence)
      limited.reduce(over)
    end

    # This is MAP query, i.e. Maximum a Posteriory
    def most_likely_value(var_name, evidence:)
      posterior_distribution = distribution(over: [var_name], evidence: evidence)
      mode = posterior_distribution.args(var_name).zip(posterior_distribution.values).max_by(&:last)
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
        factor.var node_name => node.values
      end

      factor.args(*var_names).each do |args|
        val_by_name = var_names.zip(args).to_h
        val = nodes.values.reduce(1.0) do |prob, node|
          prob * node.factor[val_by_name]
        end
        factor.val args + [val]
      end
      @joint_distribution = factor.normalize
    end
  end
end
