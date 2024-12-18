module Daidan
  module Commands
    def self.create_base_user
      require_relative 'db/connection'
      require_relative 'config/application'
      Daidan::Db::Connection.setup

      Sequel::Model.db.transaction do
        Sequel.migration do
          change do
            create_table(:users) do
              primary_key :id
              String :name, null: false
              String :email, null: false, unique: true
              String :password_digest, null: false
            end
          end
        end.apply(Sequel::Model.db, :up)
      end
      puts "Table 'users' created successfully!"
    rescue Sequel::DatabaseError => e
      raise unless e.message =~ /table `users` already exists/i

      puts "The 'users' table is already created."
    end

    def self.generate(resource_name, *fields)
      require_relative 'db/connection'
      require_relative 'config/application'
      Daidan::Db::Connection.setup

      require_relative 'generators/resource_generator'
      Daidan::Generators::ResourceGenerator.new(resource_name, fields).generate
    end
  end
end
