# -*- coding: utf-8 -*-
# Module for FoodSoft-File import
# The FoodSoft-File is a cvs-file, with semicolon-seperatet columns
 
require 'csv'

module FoodsoftFile

  def self.name
    "Foodsoft (CSV)"
  end

  def self.outlist_unlisted
    false
  end

  # returns best match if all headers are equal to any localised default header names
  def self.detect(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    csv = CSV.new(file, {:col_sep => col_sep, :headers => true})
    headers = csv.first.headers.map {|h| h.downcase.strip unless h.nil?}
    scores = I18n.available_locales.map do |locale|
      I18n.with_locale(locale) do
        locale_headers = [
          I18n.t('lib.fields.status'),
          I18n.t('activerecord.attributes.article.order_number'),
          I18n.t('activerecord.attributes.article.name'),
          I18n.t('activerecord.attributes.article.note'),
          I18n.t('activerecord.attributes.article.manufacturer'),
          I18n.t('activerecord.attributes.article.origin'),
          I18n.t('activerecord.attributes.article.unit'),
          I18n.t('activerecord.attributes.article.price'),
          I18n.t('activerecord.attributes.article.tax'),
          I18n.t('activerecord.attributes.article.deposit'),
          I18n.t('activerecord.attributes.article.unit_quantity'),
          nil,
          nil,
          I18n.t('activerecord.attributes.article.article_category'),
        ].map {|h| h.downcase.strip unless h.nil?}
        matching_headers = locale_headers.zip(csv.headers).select {|m| m[0] == m[1]}
        matching_headers.count.to_f / [locale_headers.count-2, csv.headers.count].min # don't count reserved headers
      end
    end
    scores.max
  rescue CSV::MalformedCSVError
    -1
  end
  
  # parses a string from a foodsoft-file
  # the parsed article is a simple hash
  def self.parse(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    CSV.new(file, {:col_sep => col_sep, :headers => true}).each do |row|
      # skip empty lines
      next if row[2].blank?
        
      article = {:number => row[1],
                 :name => row[2],
                 :note => row[3],
                 :manufacturer => row[4],
                 :origin => row[5],
                 :unit => row[6],
                 :price => row[7],
                 :tax => row[8],
                 :unit_quantity => row[10],
                 :scale_quantity => row[11],
                 :scale_price => row[12],
                 :category => row[13]}
      article.merge!(:deposit => row[9]) unless row[9].nil?
      article[:number].blank? and FileHelper.generate_number(article)
      if row[6].nil? || row[7].nil? or row[8].nil?
        yield article, "Error: unit, price and tax must be entered"
      else
        yield article, (row[0]=='x' ? :outlisted : nil)
      end
    end
  end
    
end
