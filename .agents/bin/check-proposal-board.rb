#!/usr/bin/env ruby
# frozen_string_literal: true

lanes = %w[1-draft 2-shape-go 3-bet-go 4-done].freeze
readme_path = "docs/proposals/README.md"
readme = File.read(readme_path, encoding: "UTF-8")
sections = {}
current_lane = nil

readme.each_line do |line|
  if (match = line.match(/^## ([1-4]) — .* \((\d+)\)$/))
    current_lane = lanes.fetch(match[1].to_i - 1)
    sections[current_lane] = {count: match[2].to_i, links: []}
  elsif line.start_with?("## ")
    current_lane = nil
  elsif current_lane
    sections.fetch(current_lane).fetch(:links).concat(line.scan(/\]\(([^)]+\/CONCEPT\.md)\)/).flatten)
  end
end

lanes.each do |lane|
  section = sections.fetch(lane) { raise "missing README lane #{lane}" }
  cards = Dir["docs/proposals/#{lane}/???-*"].select { |path| File.directory?(path) }.sort
  expected = cards.map { |card| "#{lane}/#{File.basename(card)}/CONCEPT.md" }
  raise "README count #{lane}=#{section[:count]}, expected #{cards.length}" unless section[:count] == cards.length
  raise "README duplicate #{lane}" unless section[:links].uniq.length == section[:links].length
  raise "README entries #{lane}" unless section[:links].sort == expected

  cards.each do |card|
    concept = File.join(card, "CONCEPT.md")
    raise "missing #{concept}" unless File.file?(concept)
    headings = File.read(concept, encoding: "UTF-8").scan(/^## (.+)$/).flatten
    raise "headings #{concept}" unless headings == ["Problem Statement", "Decision Made", "Consequences & Tradeoffs"]
  end
end

early_plans = lanes.first(2).flat_map { |lane| Dir["docs/proposals/#{lane}/???-*/PLAN.md"] }
raise "PLAN before Bet Go #{early_plans.join(", ")}" unless early_plans.empty?

puts "proposal board: #{lanes.sum { |lane| sections.fetch(lane).fetch(:count) }}"
