# -*- coding: utf-8 -*-
# Module for FoodSoft-File import
# The FoodSoft-File is a cvs-file, with semicolon-seperatet columns
 
require 'csv'

module FoodsoftFile

  def self.name
    "Foodsoft (CSV)"
  end

  def self.detect(data)
    0 # TODO
  end
  
  # parses a string from a foodsoft-file
  # the parsed article is a simple hash
  def self.parse(data)
    CSV.parse(data, {:col_sep => ";", :headers => true}) do |row|
      # check if the line is empty
      unless row[2] == "" || row[2].nil?
        # test, if neccecary attributes exists
        raise "Fehler: Einheit, Preis und MwSt. müssen gegeben sein" if row[6].nil? || row[7].nil? || row[8].nil?
        
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
                   :scale_price => row[12]}
        article.merge!(:deposit => row[9]) unless row[9].nil?
	yield article, (row[0]=='x' ? :outlisted : nil)
      end
    end
  end
    
end
