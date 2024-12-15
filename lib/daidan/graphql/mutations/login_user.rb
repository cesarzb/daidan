require 'jwt'
require 'yaml'

module Daidan
  class LoginUser < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true

    field :token, String, null: false
    field :user, BaseUserType, null: false

    def resolve(email:, password:)
      user = User.where(email: email).first

      raise GraphQL::ExecutionError, 'Invalid email or password' unless user && user.authenticate(password)

      payload = { user_id: user.id }

      token = JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
      { token: token, user: user }
    end
  end
end
