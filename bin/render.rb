#!/usr/bin/env ruby
require 'bundler/setup'
require 'bayesnet'
require 'graphviz'
require 'pry-byebug'

path = ARGV[0] || 'test/fixtures/asia.bif'
path = File.expand_path(path)
net = Bayesnet::Parsers::BifParser.new.build(File.read(path))

raise "Cannot parse Bayesian network in file '#{path}'" unless net

name = File.basename(path, '.*')
g = GraphViz.new(name, type: :digraph)
g.add_nodes(net.nodes.keys.map(&:to_s), shape: :record)
net.nodes.each do |node_name, node|
  g_node = g.get_node(node_name.to_s)
  dist = net.distribution(over: [node_name])
  node_content = node.values.map do |val|
    val_str = val.to_s.ljust(10, ".")
    "#{val_str} #{format('%.4f', dist[val])}\\l"
  end.join("")
  g_node[:label] = "#{node_name}\n\n#{node_content}"
  g_node[:fontname] = "Courier New"
  node.parent_nodes.each do |parent_name, _|
    g.add_edges(parent_name.to_s, node_name.to_s)
  end
end

g.output(png: "#{name}.png")
