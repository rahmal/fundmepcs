class CreateDonations < ActiveRecord::Migration
  def change
    create_table :donations do |t|
      t.integer :donor_id
      t.integer :campaign_id
      t.integer :user_id
      t.integer :amount_given_cents, default: 0, null: false
      t.timestamps null: false
      t.datetime :deleted_at
    end
    add_index :donations, :user_id
    add_index :donations, :campaign_id
  end
end
