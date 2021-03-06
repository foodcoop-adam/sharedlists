# Module for import of Willem&Drees products from their Excel sheet
# Please export the excel sheet as CSV, and import that.

require 'csv'

module WillemdreesFile

  def self.name
    "Willem&Drees"
  end

  def self.outlist_unlisted
    true
  end

  def self.detect(file, opts={})
    FileHelper.skip_until(file, /Assortiment\s+Willem\s*&\s*Drees/i).nil? ? 0 : 0.9
  end

  def self.parse(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    FileHelper.skip_until(file, /^.*Art\.\s*nr/i)
    list_variant = nil
    category = nil
    CSV.new(file, {:col_sep => col_sep, :headers => true}).each do |row|
      name = row['Omschrijving']
      # figure out which kind of list we're having
      list_variant ||= row.include?('Module') ? 'algemeen' : 'horeca'
      # (sub)categories are in first two content cells
      if name.blank?
        row[1].blank? or category = row[1]
        row[2].blank? or category = row[2]
        next
      end
      # some checks
      unit = row['Eenheid']
      unit.blank? and next # skip bottom rows with just notes
      errors = []
      unit_quantity = row['Aantal eenheden per kist']
      unit_price = parse_price(row['Prijs per eenheid'] || row['Inkoopprijs bij W&D'])
      if pack_price = parse_price(row['Prijs per kist / doos'])
        unit_price_computed = pack_price.to_f/unit_quantity.to_i
        if (unit_price_computed - unit_price.to_f).abs > 1e-2
          errors << "price per unit given #{unit_price} does not match computed " +
                    "#{pack_price}/#{unit_quantity}=#{unit_price_computed.round(2)}"
        end
      end
      # 'algemeen' variant can use 0 as unit, which probably means unit_quantity = unit-pcs
      if unit == '0'
        unit = unit_quantity
        unit_quantity = 1
      end
      # some data shuffling
      unit.gsub!(',', '.') # fix decimal sign
      unit.gsub!(/\bkilo(gram)?/, 'kg')
      unit.gsub!(/\bstuks?/, 'st')
      unit.match(/^[0-9]+$/) and unit += ' st'
      notes = []
      name.gsub!(/^W&D\s*/, '')
      name.gsub!(/\b(basis\s*ras|ras\s+[0-9]+)\s*/, '')
      name.gsub!(/\bbiologische?\b/, '') and notes << 'biologisch'
      unless row['Soort'].blank? or row['Soort']=='0'
        if m=name.match(/^(.*?)\s*(\(.*?\))\s*$/)
          name = "#{m[1]} #{row['Soort']} #{m[2]}"
        else
          name += " #{row['Soort']}"
        end
        ## We used to put more info in notes, but that resulted broad (&duplicated) names
        #if category == 'Hardfruit' and
        #   not row['Soort'].match(/^\s*div/) and
        #   not name.match(/goudreinetten/i)
        #  name += ' ' + row['Soort']
        #else
        #  notes << row['Soort']
        #end
      end
      unless row['Verpakking'].blank? or row['Verpakking']=='0' or
             row['Verpakking'].match(/\b(los|stuks?)\b/)
        notes << row['Verpakking'] unless name.index(row['Verpakking'])
      end
      if row['Art.nr'].match(/los/)
        notes << '(extra leverdag)'
      end
      unless row[1].blank? or row[1].match(/^\s*\*+\s*$/)
        notes << "(#{row[1]})"
      end
      ## until Feb 2014: in case of a crate, the unit quantity is also in the unit
      #unless row['Bestelling in kisten / dozen:'].blank?
      #  if unit.to_i == unit_quantity.to_i
      #    unit.gsub!(/^s*#{unit_quantity.to_i}\b\s*/, '')
      #  else
      #    errors << "the unit of a crate is expected to include the unit quantity"
      #  end
      #end
      # create new article
      article = {:number => row['Art.nr'],
                 #:ean => row['EAN code'], # variant 'algemeen' only
                 :name => name.strip,
                 :note => notes.count>0 ? notes.join('; ') : nil,
                 #:manufacturer => nil,
                 #:origin => nil,
                 :unit => unit,
                 :price => unit_price,
                 :unit_quantity => unit_quantity,
                 :tax => 6,
                 :deposit => 0,
                 :category => category,
                 :upload_list => list_variant,
                 }
      if errors.count > 0
        yield article, errors.join("\n")
      else
        # outlisting not used by supplier
        yield article, (row['status']=='x' ? :outlisted : nil)
      end
    end
  end

  protected

  # remove currency symbol from price
  def self.parse_price(price)
    return if price.nil?
    price.gsub(/^\s*[^0-9]+\s*/, '').gsub(',','.').to_f
  end

end
