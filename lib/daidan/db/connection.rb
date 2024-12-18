module Daidan
  module Db
    class Connection
      def self.setup(config_path = File.join(Dir.pwd, 'config', 'database.yml'))
        @db ||= begin
          db_config = YAML.load_file(config_path)['db']
          Sequel.connect(db_config).tap do |db|
            Sequel::Model.db = db
          end
        end
      end
    end
  end
end
