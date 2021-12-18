# frozen_string_literal: true

require "test_helper"

class FactorTest < Minitest::Test
  def factor
    Bayesnet::Factor.build do
      var weather: [:sunny, :cloudy]
      var mood: [:bad, :good]
      val :sunny, :bad, 0.1
      val :sunny, :good, 0.9
      val :cloudy, :bad, 0.7
      val :cloudy, :good, 0.3
    end
  end

  def normalized
    factor.normalize
  end

  def test_var_names_order_is_the_same_as_declaration_order
    assert_equal([:weather, :mood], factor.var_names)
  end

  def test_args_for_a_signle_variable
    assert_equal([[:bad], [:good]], factor.args(:mood))
    assert_equal([[:sunny], [:cloudy]], factor.args(:weather))
  end

  def test_args_for_multiple_variables
    assert_equal([[:bad, :sunny],
      [:bad, :cloudy],
      [:good, :sunny],
      [:good, :cloudy]],
      factor.args(:mood, :weather))
  end

  def test_args_for_multiple_variables_orderless
    assert_equal([[:sunny, :bad],
      [:sunny, :good],
      [:cloudy, :bad],
      [:cloudy, :good]],
      factor.args(:weather, :mood))
  end

  def test_acts_as_multinomial_map
    assert_equal(0.1, factor[:sunny, :bad])
    assert_equal(0.9, factor[:sunny, :good])
    assert_equal(0.7, factor[:cloudy, :bad])
    assert_equal(0.3, factor[:cloudy, :good])
  end

  def test_acts_as_multinomial_map_order_is_important
    assert_nil(factor[:bad, :sunny])
    assert_nil(factor[:good, :sunny])
    assert_nil(factor[:bad, :cloudy])
    assert_nil(factor[:good, :cloudy])
  end

  def test_normalized_has_same_var_names
    assert_equal([:weather, :mood], normalized.var_names)
  end

  def test_normalized_has_same_args
    assert_equal([[:bad, :sunny],
      [:bad, :cloudy],
      [:good, :sunny],
      [:good, :cloudy]],
      normalized.args(:mood, :weather))
  end

  def test_normalized_sum_of_values_is_1
    assert_equal(0.05, normalized[:sunny, :bad])
    assert_equal(0.45, normalized[:sunny, :good])
    assert_equal(0.35, normalized[:cloudy, :bad])
    assert_equal(0.15, normalized[:cloudy, :good])
    assert_equal([0.05, 0.45, 0.35, 0.15].to_set, normalized.values.to_set)
    assert_equal(1.0, normalized.values.sum)
  end

  def test_limit_by
    evidence = {weather: :sunny}
    limited = factor.limit_by(evidence)
    assert_equal([:mood], limited.var_names)
    assert_equal([[:bad], [:good]], limited.args(:mood))
    assert_equal(0.1, limited[:bad])
    assert_equal(0.9, limited[:good])
  end
end
