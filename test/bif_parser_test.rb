# frozen_string_literal: true

require 'test_helper'

class ParserTest < Minitest::Test
  def load_fixture(name)
    File.read(File.expand_path("fixtures/#{name}", __dir__))
  end

  def parser
    Bayesnet::Parsers::BifParser.new
  end

  def parse(input)
    parser.parse(input)
  end

  def test_network_declaration
    input = <<-INPUT
      network Test {}
    INPUT
    refute_nil(parse(input))
  end

  def test_network_with_single_variable
    input = <<-INPUT
      network Test {}
        variable asia {
        }
    INPUT
    refute_nil(parse(input))
  end

  def test_network_with_single_variable_and_content
    input = <<-INPUT
      network Test {}
        variable asia {
          type discrete [ 2 ] { yes, no };
        }
    INPUT
    parsed = parse(input)
    refute_nil(parsed)
    assert_equal([[:asia, %i[yes no]]], parsed.nodes)
  end

  def test_parse_values_with_various_chars
    input = <<-INPUT
      network unknown {}
      variable LowerBodyO2 {
        type discrete [ 3 ] { <5, 5-12, 12+ };
        type discrete [ 2 ] { <7.5, >=7.5  };
      }
    INPUT
    refute_nil(parse(input))
  end

  def test_network_with_two_variables_having_content
    input = <<-INPUT
      network Test {}
        variable asia {
          type discrete [ 2 ] { yes, no };
        }
        variable tub {
          type discrete [ 2 ] { yes, no };
        }
    INPUT
    refute_nil(parse(input))
  end

  def test_network_with_probability
    input = <<-INPUT
      network Test {}
      probability ( tub | asia ) {
       (yes) 0.05, 0.95;
       (no) 0.01, 0.99;
      }
    INPUT
    parsed = parse(input)
    refute_nil(parsed)
    assert_equal([{ variable: :tub,
                    parents: [:asia],
                    cpt: [{ given: [:yes], distribution: [0.05, 0.95] },
                          { given: [:no], distribution: [0.01, 0.99] }] }], parsed.cpts)
  end

  def test_network_with_two_propabilities
    input = <<-INPUT
      network Test {}
      probability ( tub | asia ) {
       (yes) 0.05, 0.95;
       (no) 0.01, 0.99;
      }
      probability ( dysp | bronc, either ) {
        (yes, yes) 0.9, 0.1;
        (no, yes) 0.7, 0.3;
        (yes, no) 0.8, 0.2;
        (no, no) 0.1, 0.9;
      }
    INPUT
    refute_nil(parse(input))
  end

  def test_network_with_table_propabilities
    input = <<-INPUT
      network Test {}
      probability ( smoke ) {
        table 0.5, 0.5;
        }
    INPUT
    refute_nil(parse(input))
  end

  def test_asia_network
    input = load_fixture('asia.bif')
    parsed = parse(input)
    refute_nil(parsed)

    assert_equal([[:asia, %i[yes no]],
                  [:tub, %i[yes no]],
                  [:smoke, %i[yes no]],
                  [:lung, %i[yes no]],
                  [:bronc, %i[yes no]],
                  [:either, %i[yes no]],
                  [:xray, %i[yes no]],
                  [:dysp, %i[yes no]]],
                 parsed.nodes)

    cpts = parsed.cpts
    assert_equal({ variable: :asia, parents: [], cpt: { table: [0.01, 0.99] } },
                 cpts[0])

    assert_equal({  variable: :tub, parents: [:asia],
                    cpt: [{ given: [:yes], distribution: [0.05, 0.95] },
                          { given: [:no], distribution: [0.01, 0.99] }] },
                 cpts[1])

    assert_equal({ variable: :smoke, parents: [], cpt: { table: [0.5, 0.5] } },
                 cpts[2])

    assert_equal({ variable: :lung, parents: [:smoke],
                   cpt: [{ given: [:yes], distribution: [0.1, 0.9] },
                         { given: [:no], distribution: [0.01, 0.99] }] },
                 cpts[3])

    assert_equal({ variable: :bronc, parents: [:smoke],
                   cpt: [{ given: [:yes], distribution: [0.6, 0.4] },
                         { given: [:no], distribution: [0.3, 0.7] }] },
                 cpts[4])

    assert_equal({ variable: :either,
                   parents: %i[lung tub],
                   cpt: [{ given: %i[yes yes], distribution: [1.0, 0.0] },
                         { given: %i[no yes], distribution: [1.0, 0.0] },
                         { given: %i[yes no], distribution: [1.0, 0.0] },
                         { given: %i[no no], distribution: [0.0, 1.0] }] },
                 cpts[5])

    assert_equal({ variable: :xray, parents: [:either],
                   cpt: [{ given: [:yes], distribution: [0.98, 0.02] },
                         { given: [:no], distribution: [0.05, 0.95] }] },
                 cpts[6])

    assert_equal({ variable: :dysp,
                   parents: %i[bronc either],
                   cpt: [{ given: %i[yes yes], distribution: [0.9, 0.1] },
                         { given: %i[no yes], distribution: [0.7, 0.3] },
                         { given: %i[yes no], distribution: [0.8, 0.2] },
                         { given: %i[no no], distribution: [0.1, 0.9] }] },
                 cpts[7])
  end

  # Medium network 20-50 nodes
  def test_insurance_network
    input = load_fixture('insurance.bif')
    refute_nil(parse(input))
  end

  # Large network 50-100 nodes
  def test_hailfinder_network
    input = load_fixture('hailfinder.bif')
    refute_nil(parse(input))
  end
end
