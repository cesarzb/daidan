require 'fileutils'

module Daidan
  module Generators
    class BaseGenerator
      def initialize(app_name)
        @app_name = app_name.strip
        validate_app_name
      end

      def generate
        create_directories
        create_files
        puts "✅ Created new app: #{@app_name}"
      end

      private

      def validate_app_name
        return if @app_name.match?(/\A[a-z0-9_]+\z/)

        puts "Invalid app name '#{@app_name}'. Use lowercase letters, numbers and underscores only."
        exit 1
      end

      def create_directories
        dirs = [
          "./#{@app_name}/config",
          "./#{@app_name}/db/migrations",
          "./#{@app_name}/graphql/mutations",
          "./#{@app_name}/graphql/types",
          "./#{@app_name}/models"
        ]
        dirs.each { |d| FileUtils.mkdir_p(d) }
      end

      def create_files
        create_application_rb
        create_database_yml
        create_config_ru
        create_gemfile
        create_schema_rb
        create_mutation_type_rb
        create_query_type_rb
        create_readme
      end

      def create_application_rb
        content = <<~RUBY
          require 'dotenv/load'
          $LOAD_PATH.unshift(File.expand_path('../../daidan/lib', __dir__))
          require 'daidan'

          class Application < Daidan::Application
            def graphql_schema
              Schema
            end
          end
        RUBY
        write_file('config/application.rb', content)
      end

      def create_database_yml
        content = <<~YAML
          db:
            adapter: sqlite
            database: db.db
        YAML
        write_file('config/database.yml', content)
      end

      def create_config_ru
        content = <<~RUBY
          require 'rack'
          require 'rack/cors'
          require_relative 'config/application'
          $LOAD_PATH.unshift(File.expand_path('../daidan/lib', __dir__))
          require 'daidan'

          use Rack::Reloader, 0

          use Rack::Cors do
            allow do
              origins '*'

              resource '/graphql',
                       headers: :any,
                       methods: %i[get post options],
                       credentials: false
            end
          end

          run Application.new
        RUBY
        write_file('config.ru', content)
      end

      def create_gemfile
        content = <<~RUBY
          source 'https://rubygems.org'

          gem 'bcrypt'
          gem 'dotenv'
          gem 'graphql'
          gem 'jwt'
          gem 'puma'
          gem 'rack'
          gem 'rubocop'
          gem 'sequel'
          gem 'sqlite3'
          gem 'zeitwerk'
          gem 'rack-cors'

          gem 'daidan', path: '../daidan'
        RUBY
        write_file('Gemfile', content)
      end

      def create_schema_rb
        content = <<~RUBY
          require 'graphql'

          class Schema < GraphQL::Schema
            query(QueryType)
            mutation(MutationType)
          end
        RUBY
        write_file('graphql/schema.rb', content)
      end

      def create_mutation_type_rb
        content = <<~RUBY
          class MutationType < Daidan::BaseObjectType
            description 'The mutation root of this schema'
          end
        RUBY
        write_file('graphql/types/mutation_type.rb', content)
      end

      def create_query_type_rb
        content = <<~RUBY
          class QueryType < Daidan::BaseObjectType
            description 'The query root of this schema'
          end
        RUBY
        write_file('graphql/types/query_type.rb', content)
      end

      def create_readme
        content = <<~MD
          # Readme

          Write something about your project here.
        MD
        write_file('readme.md', content)
      end

      def write_file(relative_path, content)
        full_path = File.join("./#{@app_name}", relative_path)
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
      end
    end
  end
end
