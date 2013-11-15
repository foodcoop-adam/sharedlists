class AddGeoToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :latitude, :float
    add_column :suppliers, :longitude, :float
    add_index :suppliers, [:latitude, :longitude]
  end
end
