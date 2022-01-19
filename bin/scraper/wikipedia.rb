#!/bin/env ruby
# frozen_string_literal: true

require 'every_politician_scraper/scraper_data'
require 'pry'

class MemberList
  class Members
    decorator RemoveReferences
    decorator UnspanAllTables
    decorator WikidataIdsDecorator::Links

    def member_items
      super.reject(&:empty?)
    end

    def member_container
      noko.xpath('//table[.//th[contains(.,"Portrait")]][last()]//tr[td]')
    end
  end

  class Member
    def empty?
      tds[0].text.to_s.include? 'Also attending'
    end

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
end

url = 'https://en.wikipedia.org/wiki/Suluhu_Cabinet'
puts EveryPoliticianScraper::ScraperData.new(url).csv
