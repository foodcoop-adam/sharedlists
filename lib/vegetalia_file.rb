require 'csv'

module VegetaliaFile

  def self.name
    "Vegetalia"
  end

  def self.outlist_unlisted
    true
  end

  def self.detect(file, opts={})
    FileHelper.skip_until(file, /VEGETALIA PRICE LIST/i, 15).nil? ? 0 : 0.9
  end
  
  def self.parse(file, opts={})
    catnote = nil
    FileHelper.skip_until(file, /VEGETALIA PRICE LIST/i, 15).nil? ? 0 : 0.9
    file.readline
    n = nil # column offset
    CSV.new(file, {:col_sep => FileHelper.csv_guess_col_sep(file), :headers => false}).each do |row|
      # first column of ranking may or may not be present; first time it's called is headerline anyway
      if n.nil?
        n = 0
        n += 1 if row[0] and row[0].match /^\s*rank(ing)?\s*$/i
        next
      end
      next if row[n].blank? and row[n+1].blank? and row[n+2].blank?
      notes = []
      # catch category note & skip empty lines
      if row[n+1] and row[n+1].match /descript/i
        catnote = (row[n+1] and m=row[n+1].match(/-\s*(.*)\s*$/)) ? m[1].capitalize : nil
        next
      end
      name = row[n+1]
      if name and m=name.match(/\b\s*(CCPAE)\b/)
        notes << m[0]
        name.gsub!(/#{m[0]}/, '')
      end
      if name and m=name.match(/^.*\b\s*([0-9,.]+\s*(kg|gr?(ams?)?|gm|m?l(tr)?)|[0-9,.]*\s*(bulbs?))\b\s*/i)
        unit = m[1]
        name.gsub! /\s*#{m[1]}\s*/, ''
        unit.gsub! /gm/, 'g' # slightly uncommon form of grams
      end
      # extra note at end of row
      notes << row[n+6] unless row[n+6].blank?
      # fix unit quantity
      unit_quantity = (row[n+5].blank? ? 1 : row[n+5])
      unit_quantity = 1 if unit_quantity == unit
      # new articles may not have an ean yet
      ean = row[n+4] unless row[n+4]
      ean = nil if ean and ean.match(/niet\s+bekend/)
      # create a new article
      notes << catnote
      article = {:number => row[n],
                 :name => (name and name.humanize),
                 :note => notes.compact.join('; '),
                 #:ean => ean,
                 :manufacturer => 'Vegetalia',
                 :origin => 'ES',
                 :unit => unit,
                 :price => row[n+2],
                 :unit_quantity => unit_quantity,
                 :tax => 6,
                 :deposit => 0,
                 :category => nil}
      # not all products may have numbers yet
      article = FileHelper.generate_number(article) if article[:number].blank?
      yield article, nil
    end
  end
end
