module Daidan
  class Application
    def initialize
      setup_zeitwerk
      super
    end

    def call(env)
      process_request(env)
    rescue JSON::ParserError
      handle_json_parse_error
    rescue StandardError => e
      handle_internal_server_error(e)
    end

    protected

    def process_request(env)
      req = Rack::Request.new(env)

      if req.post? && req.path == '/graphql'
        handle_graphql_request(req, env)
      else
        not_found_response
      end
    end

    def graphql_schema
      raise NotImplementedError, 'Subclasses must define `graphql_schema`'
    end

    def handle_json_parse_error
      [400, { 'content-type' => 'application/json' }, [{ error: 'Invalid JSON' }.to_json]]
    end

    def handle_internal_server_error(error)
      puts "Error processing request: #{error.message}"
      [500, { 'content-type' => 'application/json' }, [{ error: 'Internal Server Error' }.to_json]]
    end

    def not_found_response
      [404, { 'content-type' => 'text/plain' }, ['Not Found']]
    end

    def setup_zeitwerk
      app_root = Dir.pwd

      loader = Zeitwerk::Loader.new
      loader.push_dir(File.join(app_root, ''))
      loader.collapse(File.join(app_root, 'graphql'))
      loader.collapse(File.join(app_root, 'graphql', 'types'))
      loader.collapse(File.join(app_root, 'graphql', 'mutations'))
      loader.collapse(File.join(app_root, 'models'))
      loader.setup
    end

    private

    def handle_graphql_request(req, env)
      body = req.body.read
      params = body.empty? ? {} : JSON.parse(body)

      current_user = env['current_user_id'] ? User.find(id: env['current_user_id']) : nil

      result = graphql_schema.execute(
        params['query'],
        variables: params['variables'],
        context: { current_user: current_user },
        operation_name: params['operationName']
      )

      [200, { 'content-type' => 'application/json' }, [result.to_json]]
    end
  end
end
