class AddQuantityToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :quantity, :integer
  end
end
