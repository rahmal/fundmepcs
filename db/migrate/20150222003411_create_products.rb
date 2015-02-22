class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :description
      t.string :brand
      t.string 
      t.string :series
      t.string :model
      t.string :os
      t.string :processor
      t.string :battery
      t.string :memory
      t.string :storage
      t.string :screen
      t.string :wifi
      t.string :weight
      t.string :dimensions
      t.date :release_date
      t.string :image
      t.integer :cost_cents, default: 0, null: false
      t.timestamps null: false
      t.datetime :deleted_at
    end
    change_column :products, :cost_cents, :bigint, limit: 8
  end
end
