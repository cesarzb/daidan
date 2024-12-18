require 'sequel'

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name, null: false
      String :email, null: false, unique: true
      String :password_digest, null: false
    end
  end
end
