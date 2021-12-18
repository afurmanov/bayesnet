module Bayesnet
  # Factor if a function of sevaral variables (A, B, ...) each defined on values from finite set
  class Factor
    def self.build(&block)
      factor = new
      factor.instance_eval(&block)
      factor
    end

    # Specifies variable name together with its values
    def var(var_name_to_values)
      @vars.merge!(var_name_to_values)
    end

    # Specifies function values for args. Latest args is an function value, all previous are argument values
    def val(*args)
      args = args[0] if args.size == 1 && args[0].is_a?(Array)
      @vals[args[..-2]] = args[-1]
    end

    def var_names
      @vars.keys
    end

    def [](*args)
      key = if args.size == 1 && args[0].is_a?(Hash)
        args[0].slice(*var_names).values
      else
        args
      end
      @vals[key]
    end

    def self.from_distribution(var_distribution)
      self.class.new(var_distribution.keys, var_distribution.values.map(&:to_a))
    end

    def args(*var_names)
      return [] if var_names.empty?
      @vars[var_names[0]].product(*var_names[1..].map { |var_name| @vars[var_name] })
    end

    def values
      @vals.values
    end

    def normalize
      vals = @vals.clone
      norm_factor = vals.map(&:last).sum * 1.0
      vals.each { |k, v| vals[k] /= norm_factor }
      self.class.new(@vars.clone, vals)
    end

    def limit_by(evidence)
      vars = @vars.except(*evidence.keys)

      evidence_vals = evidence.values
      indices = evidence.keys.map { |k| index_by_var_name[k] }
      vals = @vals.select { |k, v| indices.map { |i| k[i] } == evidence_vals }
      vals.transform_keys! { |k| k - evidence_vals }

      self.class.new(vars, vals)
    end

    def reduce(over_vars)
      vars = @vars.slice(*over_vars)
      indices = vars.keys.map { |k| index_by_var_name[k] }
      vals = @vals.group_by { |args, val| indices.map { |i| args[i] } }
      vals.transform_values! { |v| v.map(&:last).sum }
      reduced = self.class.new(vars, vals)
      reduced.normalize
    end

    private

    def initialize(vars = {}, vals = {})
      @vars = vars
      @vals = vals
    end

    def index_by_var_name
      return @index_by_var_name if @index_by_var_name
      @index_by_var_name = {}
      @vars.each_with_index { |(k, v), i| @index_by_var_name[k] = i }
      @index_by_var_name
    end
  end
end
