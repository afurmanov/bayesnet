# frozen_string_literal: true

require "bayesnet/node"

module Bayesnet
  # Acyclic graph
  class Graph
    include Bayesnet::Logging

    attr_reader :nodes

    def initialize
      @nodes = {}
    end

    # +++ Graph DSL +++
    def node(name, parents: [], &block)
      raise Error, "DSL error, #node requires a &block" unless block

      node = Node.new(name, parents)
      node.instance_eval(&block)
      @nodes[name] = node
    end
    # --- Graph DSL ---

    # returns names of all nodes
    def var_names
      nodes.keys
    end

    # returns normalized distribution reduced to `evidence`
    # and marginalized over `over`
    def distribution(over: [], evidence: {}, algorithm: :variables_elimination)
      case algorithm
      when :brute_force
        joint_distribution
          .reduce_to(evidence)
          .marginalize(over)
          .normalize
      when :variables_elimination
        reduced_factors = nodes.values.map(&:factor).map { |f| f.reduce_to(evidence) }
        not_include_in_order = evidence.keys.to_set + over.to_set
        variables_order = elimination_order.reject { |v| not_include_in_order.include?(v) }
        distribution = eliminate_variables(variables_order, reduced_factors)
        distribution.normalize
      else
        raise "Uknown algorithm #{algorithm}"
      end
    end

    def elimination_order
      return @order if @order
      @order = []
      edges = Set.new
      @nodes.each do |name, node|
        parents = node.parent_nodes.keys
        parents.each { |p| edges.add([name, p].to_set) }
        parents.combination(2) { |p1, p2| edges.add([p1, p2].to_set) }
      end
      # edges now are moralized graph of `self`, just represented differently as
      # set of edges

      remaining_nodes = nodes.keys.to_set
      until remaining_nodes.empty?
        best_node = find_min_neighbor(remaining_nodes, edges)
        remaining_nodes.delete(best_node)
        @order.push(best_node)
        clique = edges.select { |e| e.include?(best_node) }
        edges -= clique
        if edges.empty? #i.e. clique is the last edge
          @order += remaining_nodes.to_a
          remaining_nodes = Set.new
        end
        clique.
          map { |e| e.delete(best_node) }.
          map(&:first).
          combination(2) { |p1, p2| edges.add([p1,p2].to_set) }
      end
      @order
    end

    def find_min_neighbor(remaining_nodes, edges)
      result = nil
      min_neighbors = nil
      remaining_nodes.each do |name, _|
        neighbors = edges.count { |e| e.include?(name) }
        if min_neighbors.nil? || neighbors < min_neighbors
          min_neighbors = neighbors
          result = name
        end
      end
      result
    end

    def eliminate_variables(variables_order, factors)
      logger.debug "Eliminating variables #{variables_order} from #{factors.size} factors #{factors.map(&:var_names)}"
      remaining_factors = factors.to_set
      variables_order.each do |var_name|
        logger.debug "Eliminating '#{var_name}'..."
        grouped_factors = remaining_factors.select { |f| f.var_names.include?(var_name) }
        remaining_factors -= grouped_factors
        logger.debug "Building new factor out of #{grouped_factors.size} factors having '#{var_name}' - #{grouped_factors.map(&:var_names)}"
        product_factor = grouped_factors.reduce(&:*)
        logger.debug "Removing variable from new factor"
        new_factor = product_factor.eliminate(var_name)
        logger.debug "New factor variables are #{new_factor.var_names}"
        remaining_factors.add(new_factor)
        logger.debug "The variable '#{var_name}' is elminated"
      end
      logger.debug "Non-eliminated variables are #{remaining_factors.map(&:var_names).flatten.uniq}"
      result = remaining_factors.reduce(&:*)
      logger.debug "Eliminating is done"
      result
    end

    # This is MAP query, i.e. Maximum a Posteriory
    # returns value of `var_name` having maximum likelihood, when `evidence` is observed
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

    # Essentially it builds product of all node's factors
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

    def resolve_factors
      @nodes.values.each do |node|
        node.resolve_factor(@nodes.slice(*node.parent_nodes))
      end
    end
  end
end
