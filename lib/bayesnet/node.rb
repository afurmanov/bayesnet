module Bayesnet
  class Node
    attr_reader :name, :parent_nodes, :factor

    def initialize(name, parent_nodes)
      @name = name
      @parent_nodes = parent_nodes
      @values = []
      @factor = Factor.new
    end

    # +++ Node DSL +++
    def values(hash_or_array = nil, &block)
      case hash_or_array
      when NilClass
        @values
      when Hash
        @values = hash_or_array.keys
        node = self
        @factor = Factor.build do
          scope node.name => node.values
          hash_or_array.each do |value, probability|
            val [value, probability]
          end
        end
      when Array
        raise Error, "DSL error, #values requires a &block when first argument is an Array" unless block
        @values = hash_or_array
        @factor = block
      end
    end

    def distributions(&block)
      instance_eval(&block)
    end
    # --- Node DSL ---

    def parameters
      (values.size - 1) * parent_nodes.values.reduce(1) { |mul, n| mul * n.values.size }
    end

    def as(distribution, given:)
      @values.zip(distribution).each do |value, probability|
        @factor.val [value] + given + [probability]
      end
    end

    def resolve_factor(parent_nodes)
      @parent_nodes = parent_nodes
      if @factor.is_a?(Proc)
        proc = @factor
        node = self
        @factor = Factor.build do
          scope node.name => node.values
          node.parent_nodes.each do |parent_node_name, parent_node|
            scope parent_node_name => parent_node.values
          end
        end
        instance_eval(&proc)
      end
    end

  end
end
