# -*- coding: utf-8 -*-
require 'csv'
require 'yaml'

# Module for translation and parsing of BNN-files (www.n-bnn.de)
# 
module BnnFile
  
 private
  @@codes = Hash.new
  @@midgard = Hash.new
  
  # Loads the codes_file config/bnn_codes.yml into the class variable @@codes
  def self.load_codes
    @@codes = YAML::load(File.open("#{Rails.root}/lib/bnn_codes.yml")).symbolize_keys
    @@midgard = YAML::load(File.open("#{Rails.root}/lib/midgard_codes.yml")).symbolize_keys
  rescue => e
    raise "Failed to load bnn_codes: #{Rails.root}/libs/...yml: #{e.message}"
  end
  
 public
  $missing_bnn_codes = Array.new
  
  # translates codes from BNN to foodsoft-code
  def self.translate(key, value)
    if @@codes[key][value]
      return @@codes[key][value]
    elsif @@midgard[key]
      return @@midgard[key][value]
    elsif value != nil
      $missing_bnn_codes << value
      return nil
    end
  end

  def self.name
    "BNN (CSV)"
  end

  def self.outlist_unlisted
    false
  end

  def self.detect(file, opts={})
    opts[:encoding].blank? and file.set_encoding('IBM850')
    0 # TODO don't know how to detect this
  end
  
  # parses a bnn-file
  def self.parse(file, opts={})
    opts[:encoding].blank? and file.set_encoding('IBM850')
    CSV.new(file, {:col_sep => ';', :headers => true}).each do |row|
      # check if the line is empty
      unless row[0] == "" || row[0].nil?
        article = {
            :name => row[6],
            :number => row[0],
            :note => row[7],
            :manufacturer => self.translate(:manufacturer, row[10]),
            :origin => row[12],
            :category => self.translate(:category, row[16]),
            :unit => row[23],
            :price => row[37],
            :tax => self.translate(:tax, row[33]),
            :unit_quantity => row[22]
        }
        # TODO: Complete deposit list....
        article.merge!(:deposit => self.translate(:deposit, row[26])) if self.translate(:deposit, row[26])

        # get scale prices if exists
        article.merge!(:scale_quantity => row[40], :scale_price => row[41]) unless row[40].nil? or row[41].nil?

        if row[62] != nil
          # consider special prices
          article[:note] = "Sonderpreis: #{article[:price]} von #{row[62]} bis #{row[63]}"
          yield article, :special

          # Check now for article status, we only consider outlisted articles right now
          # N=neu, A=Änderung, X=ausgelistet, R=Restbestand,
          # V=vorübergehend ausgelistet, W=wiedergelistet
        elsif row[1] == "X" || row[1] == "V"
          yield article, :outlisted
        else
          yield article, nil
        end
      end
    end
  end
end

# Automatically load codes:
BnnFile::load_codes
