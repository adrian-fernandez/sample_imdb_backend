class CreateActors < ActiveRecord::Migration
  def change
    create_table :actors do |table|
      table.timestamp

      table.string :imdb_id, unique: true, null: false
      table.string :name
      table.string :photo
    end

    add_index :actors, :imdb_id, unique: true
  end
end
