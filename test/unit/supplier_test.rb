# == Schema Information
#
# Table name: suppliers
#
#  id            :integer(4)      not null, primary key
#  name          :string(255)     not null
#  address       :string(255)     not null
#  phone         :string(255)     not null
#  phone2        :string(255)
#  fax           :string(255)
#  email         :string(255)
#  url           :string(255)
#  delivery_days :string(255)
#  note          :string(255)
#  created_on    :datetime
#  updated_on    :datetime
#  lists         :string(255)
#

require File.dirname(__FILE__) + '/../test_helper'

class SupplierTest < Test::Unit::TestCase
  fixtures :suppliers

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
