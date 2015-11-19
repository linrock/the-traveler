class RemovePngDataFromFaviconSnapshots < ActiveRecord::Migration
  def change
    remove_column :favicon_snapshots, :png_data
  end
end
