# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rspec'
require_relative '../../../lib/daidan/generators/resource_generator'

RSpec.describe Daidan::Generators::ResourceGenerator do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        original_stdout = $stdout
        $stdout = File.open(File::NULL, 'w')
        example.run
        $stdout = original_stdout
      end
    end
  end

  let(:resource_name) { 'post' }
  let(:fields) { ['title:string', 'body:string', 'views:integer'] }
  let(:invalid_fields) { ['invalidfield', 'name:unknown_type'] }

  describe '#generate' do
    context 'with valid resource name and fields' do
      it 'creates the necessary directories' do
        generator = described_class.new(resource_name, fields)
        generator.generate

        expected_dirs = [
          "./db/migrations",
          "./models",
          "./graphql/mutations",
          "./graphql/types"
        ]

        expected_dirs.each do |dir|
          expect(Dir.exist?(dir)).to be true
        end
      end

      it 'creates the migration file with correct content' do
        generator = described_class.new(resource_name, fields)
        generator.generate

        migrations_dir = "./db/migrations"
        migration_files = Dir["#{migrations_dir}/*.rb"]
        expect(migration_files.size).to be >= 1

        latest_migration = migration_files.max_by { |f| File.basename(f).split('_').first.to_i }
        migration_content = File.read(latest_migration)

        expect(migration_content).to include("create_table(:#{resource_name}s)")
        expect(migration_content).to include("String :title, null: false")
        expect(migration_content).to include("String :body, null: false")
        expect(migration_content).to include("Integer :views, null: false")
      end

      it 'creates the model file with correct content' do
        generator = described_class.new(resource_name, fields)
        generator.generate

        model_file = "./models/#{resource_name}.rb"
        expect(File.exist?(model_file)).to be true

        model_content = File.read(model_file)
        expect(model_content).to include("class Post < Sequel::Model")
        expect(model_content).to include("set_dataset :posts")
      end

      it 'creates the mutation files with correct content' do
        generator = described_class.new(resource_name, fields)
        generator.generate

        mutations = ['create_post.rb', 'update_post.rb', 'delete_post.rb']
        mutations.each do |mutation|
          mutation_file = "./graphql/mutations/#{mutation}"
          expect(File.exist?(mutation_file)).to be true

          mutation_content = File.read(mutation_file)
          expect(mutation_content).to include("class #{mutation.split('.rb').first.split('_').map(&:capitalize).join}")
        end
      end

      it 'creates the type file with correct content' do
        generator = described_class.new(resource_name, fields)
        generator.generate

        type_file = "./graphql/types/post_type.rb"
        expect(File.exist?(type_file)).to be true

        type_content = File.read(type_file)
        expect(type_content).to include("class PostType < Daidan::BaseObjectType")
        expect(type_content).to include("field :title, String, null: false")
        expect(type_content).to include("field :body, String, null: false")
        expect(type_content).to include("field :views, Int, null: false")
      end

      it 'injects mutations into mutation_type.rb' do
        mutation_type_dir = "./graphql/types"
        FileUtils.mkdir_p(mutation_type_dir)
        mutation_type_file = "#{mutation_type_dir}/mutation_type.rb"
        File.write(mutation_type_file, "class MutationType < Daidan::BaseObjectType\nend\n")

        generator = described_class.new(resource_name, fields)
        generator.generate

        mutation_type_content = File.read(mutation_type_file)
        expect(mutation_type_content).to include("field :create_post, mutation: CreatePost")
        expect(mutation_type_content).to include("field :update_post, mutation: UpdatePost")
        expect(mutation_type_content).to include("field :delete_post, mutation: DeletePost")
      end

      it 'injects query fields into query_type.rb' do
        query_type_dir = "./graphql/types"
        FileUtils.mkdir_p(query_type_dir)
        query_type_file = "#{query_type_dir}/query_type.rb"
        File.write(query_type_file, "class QueryType < Daidan::BaseObjectType\nend\n")

        generator = described_class.new(resource_name, fields)
        generator.generate

        query_type_content = File.read(query_type_file)
        expect(query_type_content).to include("field :posts, [PostType], null: false")
        expect(query_type_content).to include("def posts")
        expect(query_type_content).to include("Post.all")
      end
    end

    context 'with invalid resource name' do
      let(:invalid_resource) { 'InvalidName!' }

      it 'prints an error and exits' do
        expect {
          generator = described_class.new(invalid_resource, fields)
          generator.generate
        }.to raise_error(SystemExit)
      end
    end

    context 'with invalid fields' do
      it 'prints an error and exits for malformed field specification' do
        expect {
          generator = described_class.new(resource_name, ['invalidfield'])
          generator.generate
        }.to raise_error(SystemExit)
      end

      it 'prints an error and exits for invalid field name' do
        expect {
          generator = described_class.new(resource_name, ['InvalidName:string'])
          generator.generate
        }.to raise_error(SystemExit)
      end

      it 'prints an error and exits for invalid field type' do
        expect {
          generator = described_class.new(resource_name, ['title:unknown_type'])
          generator.generate
        }.to raise_error(SystemExit)
      end
    end
  end
end
