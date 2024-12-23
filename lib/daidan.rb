# frozen_string_literal: true

require 'bcrypt'
require 'dotenv/load'
require 'graphql'
require 'json'
require 'jwt'
require 'rack'
require 'sequel'
require 'yaml'
require 'zeitwerk'

require_relative 'daidan/version'
require_relative 'daidan/db/connection'
require_relative 'daidan/config/application'

Daidan::Db::Connection.setup
require_relative 'daidan/commands'

require_relative 'daidan/middleware/jwt_authentication'
require_relative 'daidan/graphql/mutations/base_mutation'
require_relative 'daidan/graphql/types/base_object_type'
require_relative 'daidan/graphql/types/base_user_type'
require_relative 'daidan/graphql/mutations/login_user'

module Daidan
  autoload :User, 'daidan/models/user'

  class Error < StandardError; end
end
