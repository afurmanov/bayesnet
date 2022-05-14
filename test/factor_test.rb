# frozen_string_literal: true

require "test_helper"

class FactorTest < Minitest::Test
  def factor
    Bayesnet::Factor.build do
      scope weather: %i[sunny cloudy]
      scope mood: %i[bad good]
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
    assert_equal(%i[weather mood], factor.var_names)
  end

  def test_contextes_for_a_signle_variable
    assert_equal([[:bad], [:good]], factor.contextes(:mood))
    assert_equal([[:sunny], [:cloudy]], factor.contextes(:weather))
  end

  def test_contextes_for_multiple_variables
    assert_equal([%i[bad sunny],
      %i[bad cloudy],
      %i[good sunny],
      %i[good cloudy]],
      factor.contextes(:mood, :weather))
  end

  def test_contextes_for_multiple_variables_orderless
    assert_equal([%i[sunny bad],
      %i[sunny good],
      %i[cloudy bad],
      %i[cloudy good]],
      factor.contextes(:weather, :mood))
  end

  def test_acts_as_multinominal_map
    assert_equal(0.1, factor[:sunny, :bad])
    assert_equal(0.9, factor[:sunny, :good])
    assert_equal(0.7, factor[:cloudy, :bad])
    assert_equal(0.3, factor[:cloudy, :good])
  end

  def test_acts_as_multinominal_map_order_is_important
    assert_nil(factor[:bad, :sunny])
    assert_nil(factor[:good, :sunny])
    assert_nil(factor[:bad, :cloudy])
    assert_nil(factor[:good, :cloudy])
  end

  def test_normalized_has_same_var_names
    assert_equal(%i[weather mood], normalized.var_names)
  end

  def test_normalized_has_same_contextes
    assert_equal([%i[bad sunny],
      %i[bad cloudy],
      %i[good sunny],
      %i[good cloudy]],
      normalized.contextes(:mood, :weather))
  end

  def test_normalized_sum_of_values_is_1
    assert_equal(0.05, normalized[:sunny, :bad])
    assert_equal(0.45, normalized[:sunny, :good])
    assert_equal(0.35, normalized[:cloudy, :bad])
    assert_equal(0.15, normalized[:cloudy, :good])
    assert_equal([0.05, 0.45, 0.35, 0.15].to_set, normalized.values.to_set)
    assert_equal(1.0, normalized.values.sum)
  end

  def test_reduce_to
    evidence = { weather: :sunny }
    limited = factor.reduce_to(evidence)
    assert_equal([:mood], limited.var_names)
    assert_equal([[:bad], [:good]], limited.contextes(:mood))
    assert_equal(0.1, limited[:bad])
    assert_equal(0.9, limited[:good])
  end

  def test_reduce_to_non_overlapping_context
    evidence = { aliens: :martians }
    limited = factor.reduce_to(evidence)
    assert_equal(factor.var_names, limited.var_names)
    assert_equal(factor.contextes, limited.contextes)
    assert_equal(factor[:sunny, :bad], limited[:sunny, :bad])
    assert_equal(factor[:sunny, :good], limited[:sunny, :good])
    assert_equal(factor[:cloudy, :bad], limited[:cloudy, :bad])
    assert_equal(factor[:cloudy, :good], limited[:cloudy, :good])
  end

  def test_product
    rain_factor = Bayesnet::Factor.build do
      scope weather: %i[sunny cloudy]
      scope rain: %i[yes no]
      val :sunny, :yes, 0.01
      val :sunny, :no, 0.99
      val :cloudy, :yes, 0.8
      val :cloudy, :no, 0.2
    end
    product = factor * rain_factor
    delta = 0.000001
    assert_equal([:weather, :mood, :rain], product.var_names)
    assert_in_delta(0.001, product[:sunny, :bad, :yes ], delta)
    assert_in_delta(0.009, product[:sunny, :good, :yes], delta)
    assert_in_delta(0.099, product[:sunny, :bad, :no], delta)
    assert_in_delta(0.891, product[:sunny, :good, :no], delta)
    assert_in_delta(0.56,  product[:cloudy, :bad, :yes], delta)
    assert_in_delta(0.24,  product[:cloudy, :good, :yes], delta)
    assert_in_delta(0.14,  product[:cloudy, :bad, :no], delta)
    assert_in_delta(0.06,  product[:cloudy, :good, :no], delta)
    product
  end
end
