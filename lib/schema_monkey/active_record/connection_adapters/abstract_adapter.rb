module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_monkey
        end

        def initialize_with_schema_monkey(*args) #:nodoc:
          initialize_without_schema_monkey(*args)

          adapter = case adapter_name
                    when /^MySQL/i                 then 'MysqlAdapter'
                    when 'PostgreSQL', 'PostGIS'   then 'PostgresqlAdapter'
                    when 'SQLite'                  then 'Sqlite3Adapter'
                    end

          SchemaMonkey.include_adapters(self.class, adapter)
          SchemaMonkey.insert_middleware(adapter)
        end

        module SchemaCreation
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_column_options!, :schema_monkey
            end
          end

          def add_column_options_with_schema_monkey!(sql, options)
            Middleware::Migration::ColumnOptionsSql.start adapter: self.instance_variable_get('@conn'), sql: sql, options: options, schema_creation: self do |env|
              add_column_options_without_schema_monkey! env.sql, env.options
            end
          end
        end
      end
    end
  end
end