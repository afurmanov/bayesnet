# frozen_string_literal: true

module Bayesnet
  # Factor if a function of several variables (A, B, ...), where
  # every variable cold take values from some finite set
  class Factor
    # +++ Factor DSL +++
    #
    # Factor DSL entry point:
    def self.build(&block)
      factor = new
      factor.instance_eval(&block)
      factor
    end

    # Factor DSL
    # Defining variable with list of its possible values looks like:
    # ```
    # Bayesnet::Factor.build do
    #   scope weather: %i[sunny cloudy]
    #   scope mood: %i[bad good]
    #   ...
    # ```
    # ^ this code defines to variables `weather` and `mood`, where
    # `weather` could be :sunny or :cloudy, and
    # `mood` could be :bad or :good
    def scope(var_name_to_values = nil)
      if var_name_to_values
        @scope.merge!(var_name_to_values)
      else
        @scope
      end
    end

    # Factor DSL
    # Specifies factor value for some set of variable values, i.e.
    # ```
    # Bayesnet::Factor.build do
    #   scope weather: %i[sunny cloudy]
    #   scope mood: %i[bad good]
    #   val :sunny, :bad, 0.1
    #   ...
    # ```
    # ^ this code says the value of factor for [weather == :sunny, mood == :bad] is 0.1
    def val(*context_and_val)
      context_and_val = context_and_val[0] if context_and_val.size == 1 && context_and_val[0].is_a?(Array)
      @vals[context_and_val[0..-2]] = context_and_val[-1]
    end
    # --- Factor DSL ---

    # List of variable names
    def var_names
      @scope.keys
    end

    # accessor factor value, i.e
    # ```
    # factor = Bayesnet::Factor.build do
    #   scope weather: %i[sunny cloudy]
    #   scope mood: %i[bad good]
    #   val :sunny, :bad, 0.1
    #   ...
    # end
    # factor[:sunny, :bad] # 0.1
    # ```
    def [](*context)
      key = if context.size == 1 && context[0].is_a?(Hash)
              context[0].slice(*var_names).values
            else
              context
            end
      @vals[key]
    end

    # returns all combinations of values of `var_names`
    def contextes(*var_names)
      return [] if var_names.empty?

      @scope[var_names[0]].product(*var_names[1..].map { |var_name| @scope[var_name] })
    end

    # returns all possible values
    def values
      @vals.values
    end

    # returns new normalized factor, i.e. where sum of all values is 1.0
    def normalize
      vals = @vals.clone
      norm_factor = vals.map(&:last).sum * 1.0
      vals.each { |k, _v| vals[k] /= norm_factor }
      self.class.new(@scope.clone, vals)
    end

    # Returns factor built as follows:
    # 1. Original factor gets filtered out by variables having values compatible with `context`
    # 2. Returned factor does not have any variables from `context` (because they have
    # same values, after step 1)
    # The `context` argument supposed to be an evidence, somewhat like
    # `{weather: :sunny}`
    def reduce_to(context)
      limited_context = context.slice(*scope.keys)
      return self.class.new(@scope, @vals) if limited_context.empty?
      limited_scope = @scope.slice(*(@scope.keys - limited_context.keys))

      context_vals = limited_context.values
      indices = limited_context.keys.map { |k| index_by_var_name[k] }
      vals = @vals.select { |k, _v| indices.map { |i| k[i] } == context_vals }
      vals.transform_keys! { |k| delete_by_indices(k, indices) }

      self.class.new(limited_scope, vals)
    end

    # Returns new context defined over `var_names`, all other variables
    # get eliminated. For every combination of `var_names`'s values
    # the value of new factor is defined by summing up values in original factor
    # having compatible value
    def marginalize(var_names)
      scope = @scope.slice(*var_names)

      indices = scope.keys.map { |k| index_by_var_name[k] }
      vals = @vals.group_by { |context, _val| indices.map { |i| context[i] } }
      vals.transform_values! { |v| v.map(&:last).sum }

      self.class.new(scope, vals)
    end

    def eliminate(var_name)
      keep_var_names = var_names
      keep_var_names.delete(var_name)
      marginalize(keep_var_names)
    end

    def select(subcontext)
      @vals.select do |context, _|
        var_names.zip(context).slice(subcontext.keys) == subcontext
      end
    end

    def *(other)
      common_scope = @scope.keys & other.scope.keys
      new_scope = scope.merge(other.scope)
      new_vals = {}
      group1 = group_by_scope_values(common_scope)
      group2 = other.group_by_scope_values(common_scope)
      group1.each do |scope, vals1|
        combo = vals1.product(group2[scope])
        combo.each do |(val1, val2)|
          # values in scope must match variables order in new_scope, i.e.
          # they must match `new_scope.var_names`
          # The code bellow ensures it by merging two hashes in the same
          # wasy as `new_scope`` is constructed above
          val_by_name1 = var_names.zip(val1.first).to_h
          val_by_name2 = other.var_names.zip(val2.first).to_h
          new_vals[val_by_name1.merge(val_by_name2).values] = val1.last*val2.last
        end
      end
      Factor.new(new_scope, new_vals)
    end

    def group_by_scope_values(scope_keys)
      indices = scope_keys.map { |k| index_by_var_name[k] }
      @vals.group_by { |context, _val| indices.map { |i| context[i] } }
    end

    private

    def delete_by_indices(array, indices)
      result = array.dup
      indices.map { |i| result[i] = nil }
      result.compact
    end

    def initialize(scope = {}, vals = {})
      @scope = scope
      @vals = vals
    end

    def index_by_var_name
      return @index_by_var_name if @index_by_var_name

      @index_by_var_name = {}
      @scope.each_with_index { |(k, _v), i| @index_by_var_name[k] = i }
      @index_by_var_name
    end
  end
end
