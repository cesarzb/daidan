require 'dotenv/load'
require 'jwt'

module Daidan
  module Middleware
    class JwtAuthentication
      def initialize(app)
        @app = app
      end

      def call(env)
        auth_header = env['HTTP_AUTHORIZATION']
        if auth_header && auth_header.start_with?('Bearer ')
          token = auth_header.split(' ').last

          begin
            payload, = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
            env['current_user_id'] = payload['user_id']
          rescue JWT::DecodeError
            env['current_user_id'] = nil
          end
        else
          env['current_user_id'] = nil
        end

        @app.call(env)
      end
    end
  end
end
