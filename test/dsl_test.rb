# frozen_string_literal: true

require "test_helper"

class DslTest < Minitest::Test
  def test_define
    assert_respond_to(Bayesnet, :define)
  end

  def test_empty_net
    assert_equal(true, Bayesnet.define.nodes.empty?)
  end

  def test_var_needs_a_block
    assert_raises Bayesnet::Error do
      Bayesnet.define { node :some }
    end
  end

  def test_var_no_parents
    net = Bayesnet.define do
      node :mood do
        values bad: 0.1, good: 0.9
      end
    end
    assert_equal(1, net.nodes.size)
    assert_equal([:bad, :good], net.nodes[:mood].values)
  end

  def test_var_with_one_parent
    net = Bayesnet.define do
      node :weather do
        values sunny: 0.8, cloudy: 0.2
      end
      node :mood, parents: [:weather] do
        values [:bad, :good] do
          as [0.1, 0.9], given: [:sunny]
          as [0.4, 0.6], given: [:cloudy]
        end
      end
    end

    assert_equal(2, net.nodes.size)

    weather = net.nodes[:weather]
    refute_nil(weather)
    assert_equal(true, weather.parent_nodes.empty?)
    assert_equal([:sunny, :cloudy], weather.values)
    assert_equal(0.8, weather.factor[:sunny])
    assert_equal(0.2, weather.factor[:cloudy])

    mood = net.nodes[:mood]
    refute_nil(net.nodes[:mood])
    assert_equal(weather, mood.parent_nodes[:weather])
    assert_equal([:bad, :good], mood.values)
    assert_equal(0.1, mood.factor[:bad, :sunny])
    assert_equal(0.9, mood.factor[:good, :sunny])
    assert_equal(0.4, mood.factor[:bad, :cloudy])
    assert_equal(0.6, mood.factor[:good, :cloudy])
    net
  end
end
