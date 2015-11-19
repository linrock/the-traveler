class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string   :url,           :null    => false
      t.boolean  :visited,       :default => false
      t.boolean  :successful
      t.string   :error_message
      t.datetime :last_visit_at
      t.timestamps
    end
    add_index :domains, :url,    :unique  => true
    add_index :domains, :visited
  end
end
