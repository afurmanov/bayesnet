# frozen_string_literal: true

require "test_helper"

class TuberculosisSkinTest < Minitest::Test
  def model
    Bayesnet.define do
      node :infected do
        values yes: 0.001, no: 0.999
      end

      node :result, parents: [:infected] do
        values [:positive, :negative] do
          distributions do
            as [0.95, 0.05], given: [:yes]
            as [0.05, 0.95], given: [:no]
          end
        end
      end
    end
  end

  def test_ifected_when_postivie
    assert_in_delta(0.019, model.chances({infected: :yes}, evidence: {result: :positive}))
  end
end
