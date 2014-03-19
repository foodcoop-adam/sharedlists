class AddUploadListToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :upload_list, :string
  end
end
