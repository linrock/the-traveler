class RenameSuccessfulColumnInDomains < ActiveRecord::Migration
  def change
    rename_column :domains, :successful, :accessed
  end
end
