class AddHashedFaviconPngIdToFaviconSnapshots < ActiveRecord::Migration
  def change
    add_column :favicon_snapshots, :hashed_favicon_png_id, :integer
    add_index  :favicon_snapshots, :hashed_favicon_png_id
  end
end
