#!/usr/bin/env ruby
#
# Scrapes articles from BD-Totaal webshop site
#   pass username and password on command-line
#
# UNFINISHED
#

require 'mechanize'
require 'set'

PRODUCTS_URL='http://shop.bd-totaal.nl/bdt.nsf/BestellenAlgemeen!OpenForm'
LOGIN_URL='http://shop.bd-totaal.nl/bdt.nsf/StartBericht!OpenForm'
USER=ARGV[0]
PASS=ARGV[1]

a = Mechanize.new

def login(a, user, pass)
  a.get LOGIN_URL do |page|
    page = page.form_with(name: '_BDTLoginForm') do |form|
      form.Username = user
      form.Password = pass
    end.submit
    yield(page) if block_given?
  end
end

def findgroups(a)
  groepen = {}
  a.get PRODUCTS_URL do |page|
    hoofdgroepen = page.search('select[name=Hoofdgroep] option').map{|o| o.inner_html.strip}
    page.search('script').each do |script|
      script = script.inner_html.to_s
      hoofdgroepen.each do |hoofdgroep|
        if script =~ /if \(value=="#{hoofdgroep}"\)\s*{\s*var\s+\w+\s*=\s*new\s+Array\s*\('(.*?)'\s*\);\s*}/m
          groepen[hoofdgroep] ||= Set.new
          groepen[hoofdgroep].merge $1.split(/'\s*,\s*'/)
        end
      end
    end
    groepen.each_key {|h| groepen[h] = groepen[h].to_a}
    yield(page, groepen) if block_given?
  end
  groepen
end

def products(page, group, subgroup)
  products = []
  page = page.form_with(name: '_BestellenAlgemeen') do |form|
    form.Hoofdgroep = group
    form.Subgroep = subgroup
    form.Artikelselectie = "#{group}~~#{subgroup}"
    form.__Click = '$Refresh'
  end.submit
  # find product list, first get header
  el = page.search('td:contains("productnaam")').first
  headers = el.parent.search('td').map(&:text)[1..-1]
  el = el.ancestors('table').first
  # then get products
  while el = el.next_sibling do
    fields = el.search('td').map(&:text).map(&:strip)
    next if fields.empty? or fields[0]==''
    # @todo convert to fields that foodsoft can understand
    products << {
      number: fields[0],
      name: fields[1],
      manufacturer: fields[2],
      note: fields[3],
      unit: fields[4],
      price: fields[5],
      article_category: "#{group}, #{subgroup}".downcase,
      # @todo add docid for ordering online later
    }
  end

  yield(page, products) if block_given?
  products
end

login(a, USER, PASS)
findgroups(a) do |page, groups|
  # @todo get all products
  # @todo generate csv, or rake task to import directly into database?
  puts products(page, groups.keys[2], groups.values[2][1])
end

