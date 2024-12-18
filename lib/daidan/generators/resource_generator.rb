require 'fileutils'
require 'sequel'

module Daidan
  module Generators
    class ResourceGenerator
      VALID_TYPES = %w[string decimal float integer].freeze

      def initialize(resource, fields)
        @resource = resource.downcase
        @class_name = @resource.capitalize
        @fields = fields
      end

      def generate
        parse_fields(@fields)
        validate_inputs
        generate_migration
        generate_model
        generate_mutations
        generate_type
        inject_mutation_type
        inject_query_type
        puts "✅ Generated resource: #{@resource}"
      end

      private

      def parse_fields(fields)
        @parsed_fields = fields.map do |f|
          name, type = f.split(':', 2)
          unless name && type && !name.empty? && !type.empty?
            puts "Invalid field specification #{f}. Use name:type."
            exit 1
          end
          unless name.match?(/\A[a-z_]+\z/)
            puts "Invalid field name '#{name}'. Use lowercase letters and underscores only."
            exit 1
          end
          unless VALID_TYPES.include?(type)
            puts "Invalid field type '#{type}'. Allowed types: #{VALID_TYPES.join(', ')}."
            exit 1
          end
          [name, type]
        end
      end

      def validate_inputs
        return if @resource.match?(/\A[a-z_]+\z/)

        puts 'Invalid resource name. Use lowercase letters and underscores only.'
        exit 1
      end

      def db_type_map
        map = {
          'string' => 'String',
          'decimal' => 'Decimal',
          'float' => 'Float',
          'integer' => 'Integer'
        }
        map.default = 'String'
        map
      end

      def graphql_type_map
        map = {
          'string' => 'String',
          'decimal' => 'Float',
          'float' => 'Float',
          'integer' => 'Int'
        }
        map.default = 'String'
        map
      end

      def generate_migration
        migrations_dir = File.join('.', 'db', 'migrations')
        FileUtils.mkdir_p(migrations_dir)
        existing = Dir[File.join(migrations_dir, '*.rb')]
        numbers = existing.map { |f| File.basename(f).split('_', 2).first.to_i }
        next_number = numbers.empty? ? 1 : numbers.max + 1
        migration_name = "create_#{@resource}s"
        table_name = "#{@resource}s"
        migration_file = File.join(migrations_dir, format("%03d_#{migration_name}.rb", next_number))

        fields = @parsed_fields.map do |(name, type)|
          db_t = db_type_map[type]
          null_part = ', null: false'
          size_part = type == 'decimal' ? ', size: [10, 2]' : ''
          "      #{db_t} :#{name}#{size_part}#{null_part}"
        end.join("\n")

        migration_content = <<~RUBY
          Sequel.migration do
            change do
              create_table(:#{table_name}) do
                primary_key :id
          #{fields}
              end
            end
          end
        RUBY

        File.write(migration_file, migration_content)
      end

      def generate_model
        models_dir = File.join('.', 'models')
        FileUtils.mkdir_p(models_dir)
        model_file = File.join(models_dir, "#{@resource}.rb")

        model_content = <<~RUBY
          class #{@class_name} < Sequel::Model
            set_dataset :#{@resource}s
          end
        RUBY

        File.write(model_file, model_content)
      end

      def generate_mutations
        mutations_dir = File.join('.', 'graphql', 'mutations')
        FileUtils.mkdir_p(mutations_dir)

        create_args = @parsed_fields.map do |(name, type)|
          gtype = graphql_type_map[type]
          "  argument :#{name}, #{gtype}, required: true"
        end.join("\n")

        update_args = @parsed_fields.map do |(name, type)|
          gtype = graphql_type_map[type]
          "  argument :#{name}, #{gtype}, required: false"
        end.join("\n")

        create_mutation_file = File.join(mutations_dir, "create_#{@resource}.rb")
        create_mutation_content = <<~RUBY
          class Create#{@class_name} < Daidan::BaseMutation
          #{create_args}

            type #{@class_name}Type

            def resolve(#{@parsed_fields.map { |f| "#{f[0]}:" }.join(', ')})
              #{@class_name}.create(#{@parsed_fields.map { |(n, t)| "#{n}: #{n}" }.join(', ')})
            rescue Sequel::Error => e
              GraphQL::ExecutionError.new("Unable to create #{@resource}: \#{e.message}")
            end
          end
        RUBY
        File.write(create_mutation_file, create_mutation_content)

        update_mutation_file = File.join(mutations_dir, "update_#{@resource}.rb")
        update_mutation_content = <<~RUBY
          class Update#{@class_name} < Daidan::BaseMutation
            argument :id, ID, required: true
          #{update_args}

            type #{@class_name}Type

            def resolve(id:, **attributes)
              record = #{@class_name}[id]
              raise GraphQL::ExecutionError, '#{@class_name} not found' unless record

              attributes.each do |k,v|
                record.update(k => v) if v
              end

              record
            rescue Sequel::Error => e
              GraphQL::ExecutionError.new("Unable to update #{@resource}: \#{e.message}")
            end
          end
        RUBY
        File.write(update_mutation_file, update_mutation_content)

        delete_mutation_file = File.join(mutations_dir, "delete_#{@resource}.rb")
        delete_mutation_content = <<~RUBY
          class Delete#{@class_name} < Daidan::BaseMutation
            argument :id, ID, required: true

            type #{@class_name}Type

            def resolve(id:)
              record = #{@class_name}[id]
              raise GraphQL::ExecutionError, '#{@class_name} not found' unless record

              record.destroy
              record
            rescue Sequel::Error => e
              GraphQL::ExecutionError.new("Unable to delete #{@resource}: \#{e.message}")
            end
          end
        RUBY
        File.write(delete_mutation_file, delete_mutation_content)
      end

      def generate_type
        types_dir = File.join('.', 'graphql', 'types')
        FileUtils.mkdir_p(types_dir)
        type_file = File.join(types_dir, "#{@resource}_type.rb")

        type_fields = @parsed_fields.map do |(name, type)|
          gtype = graphql_type_map[type]
          "  field :#{name}, #{gtype}, null: false"
        end.join("\n")

        type_content = <<~RUBY
          class #{@class_name}Type < Daidan::BaseObjectType
          #{type_fields}
          end
        RUBY

        File.write(type_file, type_content)
      end

      def inject_mutation_type
        mutation_type_file = File.join('.', 'graphql', 'types', 'mutation_type.rb')
        return unless File.exist?(mutation_type_file)

        lines = File.read(mutation_type_file).lines
        i = lines.rindex { |l| l.strip == 'end' }
        return unless i

        insert_lines = [
          "  field :create_#{@resource}, mutation: Create#{@class_name}",
          "  field :update_#{@resource}, mutation: Update#{@class_name}",
          "  field :delete_#{@resource}, mutation: Delete#{@class_name}"
        ]
        lines.insert(i, *insert_lines.map { |l| l + "\n" })
        File.write(mutation_type_file, lines.join)
      end

      def inject_query_type
        query_type_file = File.join('.', 'graphql', 'types', 'query_type.rb')
        return unless File.exist?(query_type_file)

        lines = File.read(query_type_file).lines
        i = lines.rindex { |l| l.strip == 'end' }
        return unless i

        field_lines = [
          "  field :#{@resource}s, [#{@class_name}Type], null: false do",
          "    description 'Retrieve a list of #{@resource}s'",
          '  end'
        ]
        lines.insert(i, *field_lines.map { |l| l + "\n" })

        def_lines = [
          "  def #{@resource}s",
          "    #{@class_name}.all",
          '  end'
        ]
        lines.insert(i + field_lines.size, *def_lines.map { |l| l + "\n" })

        File.write(query_type_file, lines.join)
      end
    end
  end
end
