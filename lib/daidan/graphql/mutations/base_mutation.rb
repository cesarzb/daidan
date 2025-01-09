# lib/daidan/graphql/mutations/base_mutation.rb (przykładowa ścieżka)
module Daidan
  class BaseMutation < GraphQL::Schema::Mutation
    def resolve(**args)
      call_hook(:before_mutation, **args)
      result = execute_mutation(**args)
      call_hook(:after_mutation, **args)
      result
    rescue StandardError => e
      handle_error(e)
    end

    private

    def execute_mutation(**_args)
      raise NotImplementedError, 'Implement mutation logic.'
    end

    def call_hook(hook_name, **args)
      send(hook_name, **args) if respond_to?(hook_name, true)
    end

    def handle_error(error)
      raise GraphQL::ExecutionError, "Error occured during mutation: #{error.message}"
    end
  end
end
