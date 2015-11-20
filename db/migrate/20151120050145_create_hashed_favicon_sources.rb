class CreateHashedFaviconSources < ActiveRecord::Migration
  def change
    create_table :hashed_favicon_sources do |t|
      t.string :md5_hash, :null => false
      t.binary :source_data
      t.timestamps
    end
    add_index :hashed_favicon_sources, :md5_hash, :unique => true
  end
end
