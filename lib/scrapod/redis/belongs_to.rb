# frozen_string_literal: true

require 'scrapod/redis/conn'
require 'scrapod/redis/utils'

module Scrapod
  module Redis
    module BelongsTo
      include Conn

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        include Utils

        def belongs_to(name, class_name)
          raise TypeError, "Expected name to be a #{Symbol}"              unless name.is_a? Symbol
          raise ArgumentError, "Invalid association name #{name.inspect}" unless name =~ Utils::NAME_RE

          constantizer = new_constantizer class_name

          define_belongs_to_id_getter name
          define_belongs_to_id_setter name

          define_belongs_to_getter name, constantizer
          define_belongs_to_setter name, constantizer

          define_belongs_to_nullifier name
        end

      private

        def define_belongs_to_id_getter(name)
          attr_reader :"#{name}_id"
        end

        def define_belongs_to_id_setter(name)
          define_method :"#{name}_id=" do |id|
            break send :"nullify_#{name}" if id.nil?

            raise TypeError, "Expected ID to be a #{String}" unless id.is_a? String

            if id =~ /:/
              raise ArgumentError, %(Can not set #{self.class}##{name}id to #{id.inspect} because it contains ":")
            end

            result = instance_variable_set :"@#{name}_id", id.dup.freeze
            instance_variable_set :"@#{name}", nil

            result
          end
        end

        def define_belongs_to_getter(name, constantize)
          define_method name do
            result = instance_variable_get :"@#{name}"
            break result if result
            id = instance_variable_get :"@#{name}_id"
            break if id.nil?
            instance_variable_set :"@#{name}", constantize.().find(conn, id)
          end
        end

        def define_belongs_to_setter(name, constantize)
          define_method :"#{name}=" do |record|
            break send :"nullify_#{name}" if record.nil?

            klass = constantize.()

            raise TypeError, "Expected record to be a #{klass}" unless record.is_a? klass

            send :"#{name}_id=", record.id

            send name
          end
        end

        def define_belongs_to_nullifier(name)
          define_method :"nullify_#{name}" do
            instance_variable_set :"@#{name}_id", nil
            instance_variable_set :"@#{name}",    nil
          end
        end
      end
    end
  end
end
