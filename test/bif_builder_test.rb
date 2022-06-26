# frozen_string_literal: true

require 'test_helper'

class BuilderTest < Minitest::Test
  def load_fixture(name)
    File.read(File.expand_path("fixtures/#{name}", __dir__))
  end

  def builder
    Bayesnet::Parsers::BifParser.new
  end

  def build(input)
    builder.build(input)
  end

  # small
  def test_asia_network_nodes
    input = load_fixture('asia.bif')
    asia_net = build(input)
    refute_nil(asia_net)
    assert_equal(%i[asia tub smoke lung bronc either xray dysp], asia_net.nodes.keys)
    assert_equal({}, asia_net.nodes[:asia].parent_nodes)
    assert_equal([:asia], asia_net.nodes[:tub].parent_nodes.keys)
    assert_equal({}, asia_net.nodes[:smoke].parent_nodes)
    assert_equal([:smoke], asia_net.nodes[:lung].parent_nodes.keys)
    assert_equal([:smoke], asia_net.nodes[:bronc].parent_nodes.keys)
    assert_equal(%i[lung tub], asia_net.nodes[:either].parent_nodes.keys)
    assert_equal([:either], asia_net.nodes[:xray].parent_nodes.keys)
    assert_equal(%i[bronc either], asia_net.nodes[:dysp].parent_nodes.keys)
  end

  def test_asia_network_chances
    input = load_fixture('asia.bif')
    asia_net = build(input)
    refute_nil(asia_net)
    evidence = { xray: :yes, dysp: :yes }
    assert_in_delta(0.7856, asia_net.chances({ smoke: :yes }, evidence: evidence))
    assert_in_delta(0.0140, asia_net.chances({ asia: :yes }, evidence: evidence))
    assert_in_delta(0.1139, asia_net.chances({ tub: :yes }, evidence: evidence))
    assert_in_delta(0.6213, asia_net.chances({ lung: :yes }, evidence: evidence))
    assert_in_delta(0.6819, asia_net.chances({ bronc: :yes }, evidence: evidence))
    assert_in_delta(0.7287, asia_net.chances({ either: :yes }, evidence: evidence))
  end

  # small
  def test_cancer_network_nodes
    input = load_fixture('cancer.bif')
    cancer_net = build(input)
    refute_nil(cancer_net)
    assert_equal(5, cancer_net.nodes.size)
    assert_equal(10, cancer_net.parameters)
  end

  # small
  def test_sachs_network_nodes
    input = load_fixture('sachs.bif')
    sachs_net = build(input)
    refute_nil(sachs_net)
    assert_equal(11, sachs_net.nodes.size)
    assert_equal(178, sachs_net.parameters)
  end

  # medium
  def test_insurance_network_nodes
    input = load_fixture('insurance.bif')
    insurance_net = build(input)
    refute_nil(insurance_net)
    assert_equal(27, insurance_net.nodes.size)
    assert_equal(%i[SocioEcon Age], insurance_net.nodes[:GoodStudent].parent_nodes.keys)
    # assert_equal(52, insurance_net.parameters)
    # it still running very long time > 5 mins
    # binding.pry
    # dist = insurance_net.distribution(over: [:AirBag],
    #                            evidence: { Age: :Senior,
    #                                        VehicleYear: :Older,
    #                                        Antilock: :True,
    #                                        HomeBase: :Suburb })
    # dist
    # binding.pry
  end

  # medium
  def test_child_network_nodes
    input = load_fixture('child.bif')
    child_net = build(input)
    refute_nil(child_net)
    assert_equal(20, child_net.nodes.size)
    assert_equal(230, child_net.parameters)
  end

  # medium
  def test_alarm_network
    input = load_fixture('alarm.bif')
    alarm_net = build(input)
    refute_nil(alarm_net)
    # alarm_net.joint_distribution, # this fails, OOM
  end
end
