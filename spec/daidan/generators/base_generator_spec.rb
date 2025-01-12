# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'rspec'
require_relative '../../../lib/daidan/generators/base_generator'

RSpec.describe Daidan::Generators::BaseGenerator do
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

  describe '#generate' do
    context 'with a valid app_name' do
      let(:app_name) { 'my_app' }

      it 'creates directories and core files' do
        generator = described_class.new(app_name)
        generator.generate

        expect(Dir.exist?("./#{app_name}/config")).to be true
        expect(Dir.exist?("./#{app_name}/db/migrations")).to be true
        expect(Dir.exist?("./#{app_name}/graphql/mutations")).to be true

        expect(File.exist?("./#{app_name}/config/application.rb")).to be true
        expect(File.exist?("./#{app_name}/Gemfile")).to be true
        expect(File.exist?("./#{app_name}/readme.md")).to be true
      end
    end

    context 'with an invalid app_name' do
      let(:invalid_name) { 'My App?' }

      it 'prints an error and exits' do
        expect {
          described_class.new(invalid_name).generate
        }.to raise_error(SystemExit)
      end
    end
  end
end
