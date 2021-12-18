#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'table_unspanner'
require 'wikidata_ids_decorator'

require 'open-uri/cached'

class RemoveReferences < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('sup.reference').remove
    end.to_s
  end
end

class UnspanAllTables < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('table.wikitable').each do |table|
        unspanned_table = TableUnspanner::UnspannedTable.new(table)
        table.children = unspanned_table.nokogiri_node.children
      end
    end.to_s
  end
end

class MinistersList < Scraped::HTML
  decorator RemoveReferences
  decorator UnspanAllTables
  decorator WikidataIdsDecorator::Links

  field :ministers do
    member_entries.map { |ul| fragment(ul => Officeholder).to_h }
                  .reject { |row| row[:name].include? 'Also attending' }
  end

  private

  def member_entries
    noko.xpath('//table[.//th[contains(.,"Portrait")]]//tr[td]')
  end
end

class Officeholder < Scraped::HTML
  field :wdid do
    tds[3].css('a/@wikidata').first
  end

  field :name do
    name_node ? name_node.text.tidy : tds[1].text.tidy
  end

  field :pid do
    tds[1].css('a/@wikidata').first
  end

  field :position do
    position_node ? position_node.text.tidy : tds[1].text.tidy
  end

  private

  def tds
    noko.css('td')
  end

  def name_node
    tds[3].css('a').first
  end

  def position_node
    tds[1].css('a').first
  end
end

url = 'https://en.wikipedia.org/wiki/Suluhu_Cabinet'
data = MinistersList.new(response: Scraped::Request.new(url: url).response).ministers

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
abort 'No results' if rows.count.zero?

puts header + rows.join
