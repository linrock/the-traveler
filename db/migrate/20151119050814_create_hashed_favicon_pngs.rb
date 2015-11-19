class CreateHashedFaviconPngs < ActiveRecord::Migration
  def change
    create_table :hashed_favicon_pngs do |t|
      t.string :md5_hash, :null => false
      t.binary :png_data
      t.timestamps
    end
    add_index :hashed_favicon_pngs, :md5_hash, :unique => true
  end
end
