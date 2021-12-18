# frozen_string_literal: true

require "test_helper"

class MorningMoodTest < Minitest::Test
  def morning_mood
    # Simple Bayesian network of 3 variables:
    #
    # Coffee     Sleep Hours
    #  \          /
    #   -> Mood <-

    # Values:
    #   Coffee:       yes, no
    #   Sleep Hours:  eight, seven, six
    #   Mood:         good, moderate, bad

    Bayesnet.define do
      node :coffee do
        values yes: 0.7, no: 0.3
      end

      node :sleep_hours do
        values six: 0.1, seven: 0.3, eight: 0.6
      end

      node :mood, parents: [:coffee, :sleep_hours] do
        values [:good, :moderate, :bad] do
          distributions do
            #              :mood                     :coffee  :sleep_hours
            #  [P(:good) P(:moderate), P(:bad)]
            as [0.8, 0.1, 0.1], given: [:yes, :eight]
            as [0.6, 0.2, 0.2], given: [:yes, :seven]
            as [0.4, 0.4, 0.2], given: [:yes, :six]
            as [0.7, 0.2, 0.1], given: [:no, :eight]
            as [0.5, 0.3, 0.2], given: [:no, :seven]
            as [0.3, 0.4, 0.3], given: [:no, :six]
          end
        end
      end
    end
  end

  def test_net
    mm = morning_mood
    assert_equal(3, mm.nodes.size)
    refute_nil(mm.nodes[:mood])
    refute_nil(mm.nodes[:sleep_hours])
    refute_nil(mm.nodes[:coffee])
  end

  def test_joint_distribution
    jd = morning_mood.joint_distribution
    assert_equal(1.0, jd.values.sum)
    # those values were calculated manually:
    assert_in_delta(0.336, jd[:yes, :eight, :good])
    assert_in_delta(0.027, jd[:no, :seven, :moderate])
    assert_in_delta(0.009, jd[:no, :six, :bad])
    assert_in_delta(0.018, jd[:no, :seven, :bad])
    assert_in_delta(0.018, jd[:no, :eight, :bad])
  end

  def test_most_likely
    has_drunk_coffee = morning_mood.most_likely_value(:coffee, evidence: {mood: :good, sleep_hours: :six})
    assert_equal(:yes, has_drunk_coffee)
  end

  def test_distribution_without_evidence
    distribution = morning_mood.distribution(over: [:coffee], evidence: {})
    assert_in_delta(0.7, distribution[:yes])
    assert_in_delta(0.3, distribution[:no])
  end

  def test_distribution_with_evidence
    distribution = morning_mood.distribution(over: [:coffee], evidence: {mood: :good, sleep_hours: :six})
    assert_in_delta(0.757, distribution[:yes])
    assert_in_delta(0.243, distribution[:no])
  end

  def test_distribution_over_two_vars_listed_in_different_order
    distribution1 = morning_mood.distribution(over: [:coffee, :sleep_hours], evidence: {mood: :bad})
    distribution2 = morning_mood.distribution(over: [:sleep_hours, :coffee], evidence: {mood: :bad})
    assert_in_delta(0.098, distribution1[:yes, :six])
    assert_in_delta(0.098, distribution2[:six, :yes])
    assert_in_delta(0.294, distribution1[:yes, :seven])
    assert_in_delta(0.294, distribution2[:seven, :yes])
    assert_in_delta(0.294, distribution1[:yes, :eight])
    assert_in_delta(0.294, distribution2[:eight, :yes])
    assert_in_delta(0.063, distribution1[:no, :six])
    assert_in_delta(0.063, distribution2[:six, :no])
    assert_in_delta(0.126, distribution1[:no, :seven])
    assert_in_delta(0.126, distribution2[:seven, :no])
    assert_in_delta(0.126, distribution1[:no, :eight])
    assert_in_delta(0.126, distribution2[:eight, :no])
  end

  def test_chances
    chances = morning_mood.chances({coffee: :yes}, evidence: {mood: :good, sleep_hours: :six})
    assert_in_delta(0.757, chances)
  end
end
