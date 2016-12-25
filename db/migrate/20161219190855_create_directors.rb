class CreateDirectors < ActiveRecord::Migration
  def change
    create_table :directors do |table|
      table.timestamp
      table.string :name
    end
  end
end
