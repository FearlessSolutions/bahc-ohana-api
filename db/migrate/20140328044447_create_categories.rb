class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.text :name
      t.text :oe_id
      t.text :slug

      t.timestamps
    end
    add_index :categories, :slug, unique: true
  end
end
