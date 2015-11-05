class CreateFaviconSnapshots < ActiveRecord::Migration
  def change
    create_table :favicon_snapshots do |t|
      t.string :query_url, :null => false
      t.string :final_url
      t.string :favicon_url
      t.integer :flags
      t.binary :raw_data
      t.binary :png_data
      t.timestamps
    end
    add_index :favicon_snapshots, :query_url
  end
end
