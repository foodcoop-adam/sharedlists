# Module for Kleingemaakt import

require 'csv'

module KleingemaaktFile

  def self.name
    "Klein Gemaakt"
  end

  def self.outlist_unlisted
    true
  end

  def self.detect(file, opts={})
    # when there's line starting with the firm name
    sep = FileHelper.csv_guess_col_sep(file)
    FileHelper.skip_until(file, /(\s*#{sep})*\s*Klein\s+Gemaakt\s*(#{sep}|$)/i).nil? ? 0 : 0.9
  end

  def self.parse(file, opts={})
    FileHelper.skip_until file, /^\s*art.*eenheid.*prijs.*totaal/i
    CSV.new(file, {:col_sep => FileHelper.csv_guess_col_sep(file), :headers => true}).each do |row|
      # skip empty lines
      row[0].blank? and next
      # create a new article
      article = {:number => row[0],
                 :name => row[1],
                 :note => row[2],
                 :unit => row[3],
                 :price => parse_price(row[4]),
                 :tax => parse_pct(row[5]),
                 :deposit => parse_price(row[6]),
                 :unit_quantity => row[8],
                 :manufacturer => row[15],
                 :origin => row[16],
                 :category => row[17],
                 :quantity => row[18]}
      yield article
    end
  end

  protected

  # remove currency symbol from price
  def self.parse_price(price)
    price.gsub(/^\s*[^0-9]+\s*/, '').gsub(/(\d),(\d{3})/, '\1\2').gsub(',','.').to_f
  end

  # remove percentage symbol from tax
  def self.parse_pct(pct)
    pct.gsub(/\s*%\s*$/, '').to_f
  end

end