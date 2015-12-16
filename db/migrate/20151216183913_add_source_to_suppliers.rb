class AddSourceToSuppliers < ActiveRecord::Migration
  def change
    add_column :suppliers, :source, :string
    add_column :suppliers, :source_number, :string
  end
end
