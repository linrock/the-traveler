class AddHashedFaviconSourceIdToFaviconSnapshots < ActiveRecord::Migration
  def change
    add_column :favicon_snapshots, :hashed_favicon_source_id, :integer
    add_index  :favicon_snapshots, :hashed_favicon_source_id
  end
end
