# lib/builder.rb

module Bayesnet::Parsers
  module Builder
    def build(input)
      parsed = parse(input)
      nodes = parsed.nodes.to_h

      net = Bayesnet.define do
      end

      parsed.cpts.each do |cpt|
        variable = cpt[:variable]
        case cpt[:cpt]
        when Array
          net.node(variable, parents: cpt[:parents]) do
            values nodes[variable] do
              cpt[:cpt].each do |entry|
                as entry[:distribution], given: entry[:given]
              end
            end
          end
        when Hash
          raise 'Table CPT for variable with parents is not supported' unless cpt[:parents].empty?

          table = cpt[:cpt][:table]
          net.node(variable, parents: []) do
            values nodes[variable].zip(table).to_h
          end
        end
      end

      net.resolve_factors
      net
    end
  end
end
