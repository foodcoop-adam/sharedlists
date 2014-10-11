# encoding: utf-8
# Module for FoodcoopNL file import.

require 'csv'

module FoodcoopnlFile

  def self.name
    "Foodcoop NL"
  end

  def self.outlist_unlisted
    true
  end

  # returns best match if all headers are equal to any localised default header names
  def self.detect(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    csv = CSV.new(file, {:col_sep => col_sep, :headers => true})
    headers = csv.first.headers.map {|h| h.downcase.strip unless h.nil?}
    scores = I18n.available_locales.map do |locale|
      I18n.with_locale(locale) do
        locale_headers = [
          I18n.t('lib.foodcoopnl_file.fields.order_number'),
          I18n.t('lib.foodcoopnl_file.fields.name'),
          I18n.t('lib.foodcoopnl_file.fields.note'),
          I18n.t('lib.foodcoopnl_file.fields.manufacturer'),
          I18n.t('lib.foodcoopnl_file.fields.origin'),
          I18n.t('lib.foodcoopnl_file.fields.unit'),
          I18n.t('lib.foodcoopnl_file.fields.price'),
          I18n.t('lib.foodcoopnl_file.fields.tax'),
          I18n.t('lib.foodcoopnl_file.fields.deposit'),
          I18n.t('lib.foodcoopnl_file.fields.unit_quantity'),
          I18n.t('lib.foodcoopnl_file.fields.quantity'),
          I18n.t('lib.foodcoopnl_file.fields.article_category'),
          I18n.t('lib.foodcoopnl_file.fields.storage'),
          I18n.t('lib.foodcoopnl_file.fields.ingredients'),
        ].map {|h| h.downcase.strip unless h.nil?}
        matching_headers = locale_headers.zip(csv.headers).select {|m| m[0] == m[1]}
        matching_headers.count.to_f / [locale_headers.count, csv.headers.count].min
      end
    end
    scores.max
  rescue CSV::MalformedCSVError
    -1
  end

  def self.parse(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    commentlines = I18n.available_locales.map do |locale|
      I18n.with_locale(locale) do
        I18n.t('lib.foodcoopnl_file.commentline').downcase.strip
      end
    end.uniq
    CSV.new(file, {:col_sep => col_sep, :headers => true}).each do |row|
      # skip empty lines
      next if row[1].blank?
      # skip comment line
      next if commentlines.member? row[0].downcase.strip

      article = {:number => row[0],
                 :name => row[1],
                 :note => row[2],
                 :manufacturer => row[3],
                 :origin => row[4],
                 :unit => row[5],
                 :price => parse_price(row[6]),
                 :tax => parse_pct(row[7]),
                 :deposit => parse_price(row[8]) || 0,
                 :unit_quantity => row[9],
                 :quantity => row[10],
                 :category => row[11]}
      article[:number].blank? and FileHelper.generate_number(article)
      yield article
    end
  end

  protected

  # remove currency symbol from price
  def self.parse_price(price)
    price.gsub(/^\s*[^0-9]+\s*/, '').gsub(/(\d),(\d{3})/, '\1\2').gsub(',','.').to_f unless price.nil?
  end

  # remove percentage symbol from tax
  def self.parse_pct(pct)
    pct.gsub(/\s*%\s*$/, '').to_f unless pct.nil?
  end
end
