#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/comparison'

class Comparison < EveryPoliticianScraper::Comparison
end

diff = Comparison.new('wikidata.csv', 'scraped.csv').diff
  .reject { |row| row.last.to_s =~ /Ministers? of State/i }
puts diff.sort_by { |r| [r.first, r[1].to_s] }.reverse.map(&:to_csv)
