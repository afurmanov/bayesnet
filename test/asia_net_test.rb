# frozen_string_literal: true

require 'test_helper'

class AsiaNetTest < Minitest::Test
  def net
    vars = {}
    vars[:asia] = %i[yes no]
    vars[:tub] = %i[yes no]
    vars[:smoke] = %i[yes no]
    vars[:lung] = %i[yes no]
    vars[:bronc] = %i[yes no]
    vars[:either] = %i[yes no]
    vars[:xray] = %i[yes no]
    vars[:dysp] = %i[yes no]

    Bayesnet.define do
      node :asia do
        values vars[:asia].zip([0.01, 0.99]).to_h
      end

      node :tub, parents: [:asia] do
        values vars[:tub] do
          as [0.05, 0.95], given: [:yes]
          as [0.01, 0.99], given: [:no]
        end
      end

      node :smoke do
        values vars[:smoke].zip([0.5, 0.5]).to_h
      end

      node :lung, parents: [:smoke] do
        values vars[:lung] do
          as [0.1, 0.9], given: [:yes]
          as [0.01, 0.99], given: [:no]
        end
      end

      node :bronc, parents: [:smoke] do
        values vars[:bronc] do
          as [0.6, 0.4], given: [:yes]
          as [0.3, 0.7], given: [:no]
        end
      end

      node :either, parents: %i[lung tub] do
        values vars[:either] do
          as [1.0, 0.0], given: %i[yes yes]
          as [1.0, 0.0], given: %i[no yes]
          as [1.0, 0.0], given: %i[yes no]
          as [0.0, 1.0], given: %i[no no]
        end
      end

      node :xray, parents: [:either] do
        values vars[:xray] do
          as [0.98, 0.02], given: [:yes]
          as [0.05, 0.95], given: [:no]
        end
      end

      node :dysp, parents: %i[bronc either] do
        values vars[:dysp] do
          as [0.9, 0.1], given: %i[yes yes]
          as [0.7, 0.3], given: %i[no yes]
          as [0.8, 0.2], given: %i[yes no]
          as [0.1, 0.9], given: %i[no no]
        end
      end
    end
  end

  def test_nodes
    assert_equal(8, net.nodes.size)
  end

  def test_parameters
    assert_equal(18, net.parameters)
  end

  def test_chances
    asia_net = net
    evidence = { xray: :yes, dysp: :yes }
    assert_in_delta(0.7856, asia_net.chances({ smoke: :yes }, evidence: evidence))
    assert_in_delta(0.0140, asia_net.chances({ asia: :yes }, evidence: evidence))
    assert_in_delta(0.1139, asia_net.chances({ tub: :yes }, evidence: evidence))
    assert_in_delta(0.6213, asia_net.chances({ lung: :yes }, evidence: evidence))
    assert_in_delta(0.6819, asia_net.chances({ bronc: :yes }, evidence: evidence))
    assert_in_delta(0.7287, asia_net.chances({ either: :yes }, evidence: evidence))
  end

end
