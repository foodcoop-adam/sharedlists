# == Schema Information
#
# Table name: articles
#
#  id             :integer(4)      not null, primary key
#  name           :string(255)     not null
#  supplier_id    :integer(4)      not null
#  number         :string(255)
#  note           :string(255)
#  manufacturer   :string(255)
#  origin         :string(255)
#  unit           :string(255)
#  price          :decimal(8, 2)   default(0.0), not null
#  tax            :decimal(3, 1)   default(7.0), not null
#  deposit        :decimal(8, 2)   default(0.0), not null
#  unit_quantity  :decimal(4, 1)   default(1.0), not null
#  scale_quantity :decimal(4, 2)
#  scale_price    :decimal(8, 2)
#  created_on     :datetime
#  updated_on     :datetime
#  list           :string(255)
#  category       :string(255)
#

class Article < ActiveRecord::Base
  belongs_to :supplier
  
  validates_numericality_of :price, :tax, :deposit, :unit_quantity
  validates_uniqueness_of :number, :scope => :supplier_id
  validates_presence_of :name, :price

  before_validation :parse_origin
  
  
  # Custom attribute setter that accepts decimal numbers using localized decimal separator.
  def price=(price)
    self[:price] = delocalizeDecimalString(price)
  end
  def unit_quantity=(unit_quantity)
    self[:unit_quantity] = delocalizeDecimalString(unit_quantity)
  end
  def tax=(tax)
    self[:tax] = delocalizeDecimalString(tax)
  end
  def deposit=(deposit)
    self[:deposit] = delocalizeDecimalString(deposit)
  end
  def scale_quantity=(scale_quantity)
    self[:scale_quantity] = delocalizeDecimalString(scale_quantity)
  end
  def scale_price=(scale_price)
    self[:scale_price] = delocalizeDecimalString(scale_price)
  end

  protected

  # Custom attribute setter that converts country codes to 2-letter (which we use).
  def parse_origin
    if self.origin and self.origin.match /^\s*(.*,)?\s*([^,]+)\s*$/
      origin, country = $1, $2
      c = Country.find_country_by_alpha2(country)
      c ||= Country.find_country_by_alpha3(country)
      c ||= Country.find_country_by_name(country)
      # workaround for names like België - https://github.com/hexorx/countries/issues/152
      c ||= Country.find_country_by_name(country.gsub /e$/, 'ë')
      country = c.alpha2 if c
      self.origin = [origin, country].compact.join(' ')
    end
  end

  def delocalizeDecimalString(string)
    if (string && string.is_a?(String) && !string.empty?)
      separator = ","
      if (separator != '.' && string.index(separator))
        string = string.sub(separator, '.')
      end
    end
    return string
  end
end
