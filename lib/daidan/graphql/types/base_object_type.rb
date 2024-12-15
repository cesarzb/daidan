module Daidan
  class BaseObjectType < GraphQL::Schema::Object
    field :id, ID, null: false
  end
end