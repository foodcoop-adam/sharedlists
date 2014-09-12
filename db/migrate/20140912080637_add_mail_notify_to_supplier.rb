class AddMailNotifyToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :mail_notify, :boolean
  end
end
