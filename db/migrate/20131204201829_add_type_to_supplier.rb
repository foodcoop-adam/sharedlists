class AddTypeToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :stype, :string
  end
end
