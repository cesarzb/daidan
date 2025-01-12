# frozen_string_literal: true

require 'rack'
require 'json'
require 'rspec'
require 'zeitwerk'
require_relative '../../../lib/daidan/config/application'

RSpec.describe Daidan::Application do
  before do
    allow_any_instance_of(Daidan::Application).to receive(:setup_zeitwerk)
    allow_any_instance_of(Daidan::Application).to receive(:puts)
  end

  let(:app) { described_class.new }

  describe '#call' do
    let(:env) { {} }

    context 'when process_request runs without error' do
      it 'calls process_request' do
        expect(app).to receive(:process_request).with(env)
        app.call(env)
      end
    end

    context 'when JSON::ParserError is raised' do
      before do
        allow(app).to receive(:process_request).and_raise(JSON::ParserError)
      end

      it 'returns a 400 response' do
        status, headers, body = app.call(env)
        expect(status).to eq(400)
        expect(headers['content-type']).to eq('application/json')
        expect(body.join).to include('Invalid JSON')
      end
    end

    context 'when another StandardError is raised' do
      before do
        allow(app).to receive(:process_request).and_raise(StandardError, 'Something went wrong')
      end

      it 'returns a 500 response' do
        status, headers, body = app.call(env)
        expect(status).to eq(500)
        expect(headers['content-type']).to eq('application/json')
        expect(body.join).to include('Internal Server Error')
      end
    end
  end

  describe '#process_request' do
    let(:req) { instance_double(Rack::Request, post?: post?, path: path, body: nil) }
    let(:env) { {} }

    before do
      allow(Rack::Request).to receive(:new).and_return(req)
    end

    context 'when POST to /graphql' do
      let(:post?) { true }
      let(:path)  { '/graphql' }

      it 'calls handle_graphql_request' do
        expect(app).to receive(:handle_graphql_request).with(req, env)
        app.send(:process_request, env)
      end
    end

    context 'otherwise' do
      let(:post?) { false }
      let(:path)  { '/some_other_path' }

      it 'returns a 404 Not Found response' do
        status, headers, body = app.send(:process_request, env)
        expect(status).to eq(404)
        expect(headers['content-type']).to eq('text/plain')
        expect(body.join).to eq('Not Found')
      end
    end
  end

  describe '#handle_graphql_request' do
    let(:req)      { instance_double(Rack::Request, body: StringIO.new(body_content)) }
    let(:env)      { { 'current_user_id' => 123 } }
    let(:body_content) { { query: 'testQuery', variables: {}, operationName: nil }.to_json }
    let(:mock_user)    { double('User') }
    let(:mock_schema)  { double('GraphQLSchema') }
    let(:mock_result)  { { data: { test: 'value' } } }

    before do
      stub_const('User', Class.new)
      allow(User).to receive(:find).with(id: 123).and_return(mock_user)

      allow(app).to receive(:graphql_schema).and_return(mock_schema)

      allow(mock_schema).to receive(:execute).and_return(mock_result)
    end

    it 'returns a successful 200 response with JSON result' do
      status, headers, body = app.send(:handle_graphql_request, req, env)
      expect(status).to eq(200)
      expect(headers['content-type']).to eq('application/json')
      expect(body.join).to include('test')
    end
  end
end
