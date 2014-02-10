# Module for import of TerraSana products from their Excel sheet
# Please export the excel sheet as CSV, and import that.
 
require 'csv'

module MattissonFile

  def self.name
    "Mattisson"
  end

  def self.outlist_unlisted
    true
  end

  def self.detect(file, opts={})
    FileHelper.skip_until(file, /MATTISSON HEALTHCARE/i, 4).nil? ? 0 : 0.9
  end
  
  def self.parse(file, opts={})
    category = nil
    FileHelper.skip_until(file, /OMSCHRIJVING/i, 15).nil? ? 0 : 0.9
    file.readline
    CSV.new(file, {:col_sep => FileHelper.csv_guess_col_sep(file), :headers => true}).each do |row|
      # skip empty lines
      row[1].blank? and next
      # categories take their own line
      if row[0].blank?
        category = row[1].gsub(/(\s)\s*/, '\1').capitalize
        next
      end
      unit = row[2].gsub(/\.\s*$/, '')
      # create a new article
      article = {:number => row[0],
                 :name => row[1],
                 #:manufacturer => nil,
                 #:origin => nil,
                 :unit => unit,
                 :price => row[3],
                 :unit_quantity => 1,
                 :tax => row[5],
                 :deposit => 0,
                 :category => category}
      yield article, nil
    end
  end
    
end
