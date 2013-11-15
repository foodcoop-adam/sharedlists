# Module for import of BioRomeo products from their Excel sheet
# Please export the excel sheet as CSV, and import that.

require 'csv'

module BioromeoFile

  def self.name
    "BioRomeo (CSV)"
  end

  def self.detect(file, opts={})
    FileHelper.skip_until(file, /@bioromeo\.nl/i, 10).nil? ? 0 : 0.9
  end

  def self.parse(file, opts={})
    col_sep = FileHelper.csv_guess_col_sep(file)
    FileHelper.skip_until(file, /^.*Prijs\s+per/i)
    category = nil
    headclean = Proc.new {|x| x.gsub(/^\s*(.*?)\s*$/, '\1') unless x.nil?} # remove whitespace around headers
    CSV.new(file, {:col_sep => col_sep, :headers => true, :header_converters => headclean}).each do |row|
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
      res = [ /\b((per|a)\s*)?([0-9,.]+\s*x\s*[0-9,.]+\s*(kg|gr|gram|st|stuks?|bos|bosjes?|liter|ltr|bol))\b/i,
              /\b((per|a)\s*)?([0-9,.]+\s*(kg|gr|gram|st|stuks?|bos|bosjes?|liter|ltr|bol)\s+x\s*[0-9,.]+)\b/i,
              /\b((per|a)\s*)?([0-9,.]+\s*(kg|gr|gram|st|stuks?|bos|bosjes?|liter|ltr|bol))\b/i,
              /\b((per|a)\s*)?((kg|gr|gram|st|stuks?|bos|bosjes?|liter|ltr|bol))\b/i ]
      res.each do |re|
        if m=name.match(re)
          unit = m[3].gsub(',', '.').gsub(/^per\s*/,'').gsub(/^1\s*([^0-9.])/,'\1').gsub(/^a\b\s*/,'')
          unit = unit.gsub(/bosjes?/, 'bos').gsub('liter','ltr').gsub(/stuks?/, 'st').gsub('gram','gr')
          name = name.gsub(re, '').gsub(/\(\)\s*$/,'').gsub(/\s+-\s*/,' ')
          break
        end
      end
      if unit.nil?
        unit = '?'
        errors << "Cannot find unit in name '#{name}'"
      end
      name.gsub! /\s*-?\s*$/, ''
      if unit.match(/x/i)
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
      # note from various fields
      msg = ''
      unless row[1].blank?
        msg = "Beschikbaar: #{row[1]}"
        msg += " t/m #{row[2]}" unless row[2].blank?
      end
      msg += " (#{row[6]})" unless row[6].blank?
      notes << msg unless msg.blank?
      # create new article
      errors << check_price(unit, unit_quantity, unit_price, pack_price)
      article = {:number => name,
                 :name => name,
                 :note => notes.count>0 ? notes.join("\n") : nil,
                 #:manufacturer => nil,
                 :origin => 'Noordoostpolder',
                 :unit => unit,
                 :price => pack_price.to_f/unit_quantity.to_f,
                 :unit_quantity => unit_quantity,
                 :tax => 6,
                 :deposit => 0,
                 :category => category
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

    amount, what = unit.split /\s+/, 2

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

end
