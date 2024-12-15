# frozen_string_literal: true

require_relative 'daidan/version'
require_relative 'daidan/db/connection'
require_relative 'daidan/config/application'

Daidan::Db::Connection.setup

require_relative 'daidan/middleware/jwt_authentication'
require_relative 'daidan/models/user'
require_relative 'daidan/graphql/mutations/base_mutation'
require_relative 'daidan/graphql/types/base_object_type'
require_relative 'daidan/graphql/types/base_user_type'
require_relative 'daidan/graphql/mutations/login_user'

module Daidan
  class Error < StandardError; end
end
