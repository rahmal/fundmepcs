class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.integer :user_id
      t.integer :product_id
      t.string :title
      t.integer :amount_needed_cents, default: 0, null: false
      t.integer :amount_raised_cents, default: 0, null: false
      t.timestamps null: false
      t.datetime :deleted_at
    end
    change_column :campaigns, :amount_needed_cents, :bigint, limit: 8
    change_column :campaigns, :amount_raised_cents, :bigint, limit: 8
    add_index :campaigns, :user_id
    add_index :campaigns, :product_id
  end
end
