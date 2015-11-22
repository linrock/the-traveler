class RemoveSourceDataFromFaviconSnapshots < ActiveRecord::Migration
  def change
    remove_column :favicon_snapshots, :source_data
  end
end
