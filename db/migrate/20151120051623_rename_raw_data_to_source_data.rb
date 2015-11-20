class RenameRawDataToSourceData < ActiveRecord::Migration
  def change
    rename_column :favicon_snapshots, :raw_data, :source_data
  end
end
