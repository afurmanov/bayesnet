module Bayesnet
  # Factor if a function of sevaral variables (A, B, ...) each defined on values from finite set
  class Factor
    def self.build(&block)
      factor = new
      factor.instance_eval(&block)
      factor
    end

    # Specifies variable name together with its values
    def scope(var_name_to_values)
      @scope.merge!(var_name_to_values)
    end

    # Specifies value for a scope context. Value is the last element in `context_and_val`
    def val(*context_and_val)
      if context_and_val.size == 1 && context_and_val[0].is_a?(Array)
        context_and_val = context_and_val[0]
      end
      @vals[context_and_val[0..-2]] = context_and_val[-1]
    end

    def var_names
      @scope.keys
    end

    def [](*context)
      key = if context.size == 1 && context[0].is_a?(Hash)
        context[0].slice(*var_names).values
      else
        context
      end
      @vals[key]
    end

    def self.from_distribution(var_distribution)
      self.class.new(var_distribution.keys, var_distribution.values.map(&:to_a))
    end

    def contextes(*var_names)
      return [] if var_names.empty?
      @scope[var_names[0]].product(*var_names[1..].map { |var_name| @scope[var_name] })
    end

    def values
      @vals.values
    end

    def normalize
      vals = @vals.clone
      norm_factor = vals.map(&:last).sum * 1.0
      vals.each { |k, v| vals[k] /= norm_factor }
      self.class.new(@scope.clone, vals)
    end

    def reduce_to(context)
      # todo: use Hash#except when Ruby 2.6 support no longer needed
      context_keys_set = context.keys.to_set
      scope = @scope.reject { |k, _| context_keys_set.include?(k) }

      context_vals = context.values
      indices = context.keys.map { |k| index_by_var_name[k] }
      vals = @vals.select { |k, v| indices.map { |i| k[i] } == context_vals }
      vals.transform_keys! { |k| k - context_vals }

      self.class.new(scope, vals)
    end

    # groups by `var_names` having same context and sum out values.
    def marginalize(var_names)
      scope = @scope.slice(*var_names)

      indices = scope.keys.map { |k| index_by_var_name[k] }
      vals = @vals.group_by { |context, val| indices.map { |i| context[i] } }
      vals.transform_values! { |v| v.map(&:last).sum }

      self.class.new(scope, vals)
    end

    private

    def initialize(scope = {}, vals = {})
      @scope = scope
      @vals = vals
    end

    def index_by_var_name
      return @index_by_var_name if @index_by_var_name
      @index_by_var_name = {}
      @scope.each_with_index { |(k, v), i| @index_by_var_name[k] = i }
      @index_by_var_name
    end
  end
end
