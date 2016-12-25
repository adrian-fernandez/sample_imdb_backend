class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |table|
      table.timestamps

      table.string :username
      table.string :password
      table.string :password_digest
      table.string :token, limit: 256
    end
  end
end
