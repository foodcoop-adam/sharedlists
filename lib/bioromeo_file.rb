# Module for import of BioRomeo products from their Excel sheet
# Please export the excel sheet as CSV, and import that.

require 'csv'

module BioromeoFile

  RE_UNITS = /(kg|gr|gram|pond|st|stuks?|bos|bosjes?|liter|ltr|ml|bol|krop)/
  RES_PARSE_UNIT_LIST = [
    /\b((per|a)\s*)?([0-9,.]+\s*x\s*[0-9,.]+\s*#{RE_UNITS})\b/i,                     # 1x5 kg
    /\b((per|a)\s*)?([0-9,.]+\s*#{RE_UNITS}\s+x\s*[0-9,.]+)\b/i,                     # 1kg x 5
    /\b((per|a)\s*)?(([0-9,.]+\s*,\s+)*[0-9,.]+\s+of\s+[0-9,.]+\s*#{RE_UNITS})\b/i,  # 1, 2 of 5 kg
    /\b((per|a)\s*)?([0-9,.]+\s*#{RE_UNITS})\b/i,                                    # 1kg
    /\b((per|a)\s*)?(#{RE_UNITS})\b/i                                                # kg
  ]
  # first parse with dash separator at the end, fallback to less specific
  RES_PARSE_UNIT = RES_PARSE_UNIT_LIST.map {|r| /- #{r}\s*$/} +
                   RES_PARSE_UNIT_LIST.map {|r| /- #{r}/} +
                   RES_PARSE_UNIT_LIST

  def self.name
    "BioRomeo"
  end

  def self.outlist_unlisted
    true
  end

  def self.detect(file, opts={})
    FileHelper.skip_until(file, /@bioromeo\.nl/i, 10).nil? ? 0 : 0.9
  end

  def self.parse(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    linenum = FileHelper.skip_until(file, /^.*Prijs\s+per/i)-1
    category = nil
    headclean = Proc.new {|x| x.gsub(/^\s*(.*?)\s*$/, '\1') unless x.nil?} # remove whitespace around headers
    CSV.new(file, {:col_sep => col_sep, :headers => true, :header_converters => headclean}).each do |row|
      linenum += 1
      row[0].blank? and next
      # (sub)categories are in first two content cells
      if row[1].blank? and row[3].blank? and row[4].blank?
        category = row[0]
        next
      end
      # extract name and unit
      errors = []
      notes = []
      unit_price = parse_price(row[3])
      pack_price = parse_price(row[4])
      name = row[0]
      unit = nil
      RES_PARSE_UNIT.each do |re|
        m=name.match(re) or next
        unit = self.normalize_unit(m[3])
        name = name.sub(re, '').sub(/\(\s*\)\s*$/,'').sub(/\s+-\s*/,' ')
        break
      end
      if unit.nil?
        unit = '?'
        errors << "Cannot find unit in name '#{name}'"
      end
      # handle multiple units in one line
      if unit.match /\b(,\s+|of)\b/
        # TODO create multiple articles instead of taking first one
      end
      # Ad-hoc fix for package of eggs: always take pack price
      if name.match /^Eieren/
        unit_price = pack_price
      end
      # figure out unit_quantity
      name.gsub! /\s*-?\s*$/, ''
      if unit.match(/x/)
        unit_quantity, unit = unit.split /\s*x\s*/i, 2
        unit,unit_quantity = unit_quantity,unit if unit_quantity.match(/[a-z]/i)
      elsif (unit_price-pack_price).abs < 1e-3
        unit_quantity = 1
      elsif m=unit.match(/^(.*)\b\s*(st|bos|bosjes?)\s*$/i)
        unit_quantity, unit = m[1..2]
        unit_quantity.blank? and unit_quantity = 1
      else
        unit_quantity = 1
      end
      # there may be a more informative unit in the line
      if unit=='st'
        RES_PARSE_UNIT.each do |re|
          m=name.match(re) or next
          unit = self.normalize_unit(m[3])
          name = name.sub re, ''
        end
      end
      # note from various fields
      msg = ''
      unless row[1].blank?
        msg = "Beschikbaar: #{row[1]}"
        msg += " t/m #{row[2]}" unless row[2].blank?
      end
      msg += " (#{row[6]})" unless row[6].blank?
      notes << msg unless msg.blank?
      # unit check
      errors << check_price(unit, unit_quantity, unit_price, pack_price)
      # create new article
      name = name.sub(/\s+$/, '')
      article = {:name => name,
                 :note => notes.count>0 ? notes.join("\n") : nil,
                 #:manufacturer => nil,
                 :origin => 'Noordoostpolder, NL',
                 :unit => unit,
                 :price => pack_price.to_f/unit_quantity.to_f,
                 :unit_quantity => unit_quantity,
                 :tax => 6,
                 :deposit => 0,
                 :category => category,
                 :srcdata => {file: opts[:filename] || File.basename(file.to_path), row: linenum, col: 5}
                 }
      FileHelper.generate_number(article)
      errors.compact!
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
    price.gsub(/^\s*[^0-9]+\s*/, '').gsub(/(\d),(\d{3})/, '\1\2').gsub(',','.').to_f
  end

  def self.check_price(unit, unit_quantity, unit_price, pack_price)
    if (unit_price-pack_price).abs < 1e-3
      return if unit_quantity == 1
      return "price per unit #{unit_price} is pack price, but unit quantity #{unit_quantity} is not one"
    end

    amount, what = unit.match(/^(.*)(#{RE_UNITS})\s*$/)[1..2]

    # perhaps unit price is kg-price
    kgprice = if what=='kg'
                pack_price.to_f / amount.to_f
              elsif what and what.match(/^gr/)
                pack_price.to_f / amount.to_f * 1000
              end
    if not kgprice.nil? and (kgprice - unit_price.to_f).abs < 1e-2
      return
    end

    unit_price_computed = pack_price.to_f/unit_quantity.to_i
    if (unit_price_computed - unit_price.to_f).abs > 1e-2
      "price per unit given #{unit_price} does not match computed " +
        "#{pack_price}/#{unit_quantity}=#{unit_price_computed.round(2)}" +
        (kgprice ? " (nor is it a kg-price #{kgprice})" : '')
    end
  end

  def self.normalize_unit(unit)
    unit = unit.sub(/,([0-9])/, '.\1').gsub(/^per\s*/,'').sub(/^1\s*([^0-9.])/,'\1').sub(/^a\b\s*/,'')
    unit = unit.sub(/bosjes?/, 'bos').sub('liter','ltr').sub(/stuks?/, 'st').sub('gram','gr')
  end

end
