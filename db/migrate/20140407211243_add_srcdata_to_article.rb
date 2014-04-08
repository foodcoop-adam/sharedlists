class AddSrcdataToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :srcdata, :text
  end
end
