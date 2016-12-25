class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |table|
      table.timestamps
      table.string :imdb_id, limit: 9, null: false, unique: true

      table.string :title
      table.references :director
      table.string :actor_ids, array: true, default: []
      table.integer :year
      table.float :rate
      table.string :poster
    end

    add_index :movies, :imdb_id, unique: true
    add_index :movies, :title, unique: true
    add_index :movies, :director_id
    add_index :movies, :actor_ids
  end
end
