# Module for import of BioRomeo products from their Excel sheet, from Aug 2014
# Please export the excel sheet as CSV, and import that.

require 'csv'

module BioromeoCFile

  RE_UNITS = /(kg|gr|gram|pond|st|stuks?|bos|bossen|bosjes?|liter|ltr|ml|bol|krop)(\s*\.)?/i
  RES_PARSE_UNIT_LIST = [
    /\b((per|a)\s*)?([0-9,.]+\s*x\s*[0-9,.]+\s*#{RE_UNITS})/i,                     # 1x5 kg
    /\b((per|a)\s*)?([0-9,.]+\s*#{RE_UNITS}\s+x\s*[0-9,.]+)/i,                     # 1kg x 5
    /\b((per|a)\s*)?(([0-9,.]+\s*,\s+)*[0-9,.]+\s+of\s+[0-9,.]+\s*#{RE_UNITS})/i,  # 1, 2 of 5 kg
    /\b((per|a)\s*)?([0-9,.]+\s*#{RE_UNITS})/i,                                    # 1kg
    /\b((per|a)\s*)?(#{RE_UNITS})/i                                                # kg
  ]
  # first parse with dash separator at the end, fallback to less specific
  RES_PARSE_UNIT = RES_PARSE_UNIT_LIST.map {|r| /-\s*#{r}\s*$/} +
                   RES_PARSE_UNIT_LIST.map {|r| /-\s+#{r}/} +
                   RES_PARSE_UNIT_LIST.map {|r| /#{r}\s*$/} +
                   RES_PARSE_UNIT_LIST.map {|r| /-#{r}/}

  def self.name
    "BioRomeo (version B)"
  end

  def self.outlist_unlisted
    true
  end

  def self.detect(file, opts={})
    FileHelper.skip_until(file, /@bioromeo\.nl/i, 10).nil? and return 0
    FileHelper.skip_until(file, /^\s*Art.*Product.*Skal.*Demeter.*Bestel/i, 15).nil? and return 0
    return 0.9
  end

  def self.parse(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    linenum = FileHelper.skip_until(file, /^.*Prijs\s+per/i)-1
    category = ''
    headclean = Proc.new {|x| x.gsub(/^\s*(.*?)\s*$/, '\1') unless x.nil?} # remove whitespace around headers
    CSV.new(file, {:col_sep => col_sep, :headers => true, :header_converters => headclean}).each do |row|
      linenum += 1
      row[1].blank? and next
      # (sub)categories are in first two content cells - assume if there's a price it's a product
      if row[4].blank? and row[5].blank?
        category = row[1]
        next
      end
      # skip products without a number
      row[0].blank? and next 
      # extract name and unit
      errors = []
      notes = []
      unit_price = parse_price(row[4])
      pack_price = parse_price(row[5])
      number = row[0]
      name = row[1]
      unit = nil
      manufacturer = nil
      prod_category = nil
      RES_PARSE_UNIT.each do |re|
        m=name.match(re) or next
        unit = self.normalize_unit(m[3])
        name = name.sub(re, '').sub(/\(\s*\)\s*$/,'').sub(/\s+/, ' ').sub(/\.\s*$/, '').strip
        break
      end
      unit ||= '1 st' if name.match /\bsla\b/i
      unit ||= '1 bos' if name.match /\bradijs\b/i
      unit ||= '1 bosje' if category.match /\bkruid/i
      if unit.nil?
        unit = '?'
        errors << "Cannot find unit in name '#{name}'"
      end
      # handle multiple units in one line
      if unit.match /\b(,\s+|of)\b/
        # TODO create multiple articles instead of taking first one
      end
      # sometimes category is also used to indicate manufacturer
      m=category.match(/((eko\s*)?boerderij.*?)\s*$/i) and manufacturer = m[1]
      # Ad-hoc fix for package of eggs: always take pack price
      if name.match /^eieren/i
        unit_price = pack_price
        prod_category = 'Eieren'
      end
      prod_category = 'Kaas' if name.match /^kaas/i
      # figure out unit_quantity
      if unit.match(/x/)
        unit_quantity, unit = unit.split /\s*x\s*/i, 2
        unit,unit_quantity = unit_quantity,unit if unit_quantity.match(/[a-z]/i)
      elsif (unit_price-pack_price).abs < 1e-3
        unit_quantity = 1
      elsif m=unit.match(/^(.*)\b\s*(st|bos|bossen|bosjes?)\.?\s*$/i)
        unit_quantity, unit = m[1..2]
        unit_quantity.blank? and unit_quantity = 1
      else
        unit_quantity = 1
      end
      # sometimes the pack price is used as a comment about the pricing
      if row[5].match /nac[au]lculatie/i
        pack_price = unit_price
        unit_quantity = 1
      end
      # there may be a more informative unit in the line
      if unit=='st' and not name.match(/kool/i)
        RES_PARSE_UNIT.each do |re|
          m=name.match(re) or next
          unit = self.normalize_unit(m[3])
          name = name.sub(re, '').strip
        end
      end
      # note from various fields
      notes.append "#{row.headers[2].strip} #{row[2].gsub(/#{row.headers[2].strip}/i, '').strip}" unless row[2].blank? # Skal
      notes.append "#{row.headers[3].strip} #{row[3].gsub(/#{row.headers[3].strip}/i, '').strip}" unless row[3].blank? # Demeter
      notes.append "(#{row[7].strip})" unless row[7].blank? # note
      name.sub!(/(,\.?\s*)?\bDemeter\b/i, '') and notes.prepend("Demeter")
      name.sub!(/(,\.?\s*)?\bBIO\b/i, '') and notes.prepend "BIO"
      # unit check
      errors << check_price(unit, unit_quantity, unit_price, pack_price)
      # create new article
      name.gsub! /\s+/, ' '
      article = {:number => number,
                 :name => name.strip,
                 :note => notes.count>0 ? notes.map(&:strip).join("; ") : nil,
                 :manufacturer => manufacturer,
                 :origin => 'Noordoostpolder, NL',
                 :unit => unit,
                 :price => pack_price.to_f/unit_quantity.to_f,
                 :unit_quantity => unit_quantity,
                 :tax => 6,
                 :deposit => 0,
                 :category => prod_category || category,
                 :srcdata => {file: opts[:filename] || File.basename(file.to_path), row: linenum, col: 5}
                 }
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

    if m = unit.match(/^(.*)(#{RE_UNITS})\s*$/)
      amount, what = m[1..2]
    else
      return "could not parse unit: #{unit}"
    end

    # perhaps unit price is kg-price
    kgprice = if what =~ /^kg/i
                pack_price.to_f / amount.to_f
              elsif what =~ /^gr/
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
    unit = unit.sub(/1\s*x\s*/, '')
    unit = unit.sub(/,([0-9])/, '.\1').gsub(/^per\s*/,'').sub(/^1\s*([^0-9.])/,'\1').sub(/^a\b\s*/,'')
    unit = unit.sub(/(bossen|bosjes?)/, 'bos').sub('liter','ltr').sub(/stuks?/, 'st').sub('gram','gr')
    unit = unit.sub(/\s*\.\s*$/,'').sub(/\s+/, ' ').strip
  end

end
