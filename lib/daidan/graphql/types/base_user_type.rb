module Daidan
  class BaseUserType < Daidan::BaseObjectType
    field :email, String, null: false
  end
end