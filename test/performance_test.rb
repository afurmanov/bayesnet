# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class PerformanceTest < Minitest::Test
  def test_chances_benchmark
    input = load_fixture('alarm.bif')
    alarm_net = build(input)
    #evidence = { xray: :yes, dysp: :yes }
    # bm = Benchmark.measure do
    #   100.times { asia_net.chances({ smoke: :yes }, evidence: evidence)}
    # end
    # puts bm
  end
end
