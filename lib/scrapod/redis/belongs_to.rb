# frozen_string_literal: true

require 'redis'

require 'scrapod/redis/utils'

module Scrapod
  module Redis
    module BelongsTo
      include Utils

      def belongs_to(name, class_name)
        raise TypeError, "Expected name to be a #{Symbol}"              unless name.is_a? Symbol
        raise ArgumentError, "Invalid association name #{name.inspect}" unless name =~ Utils::NAME_RE

        raise TypeError, "Expected class name to be a #{String}"        unless class_name.is_a? String
        raise ArgumentError, "Invalid class name #{class_name.inspect}" unless class_name =~ Utils::CLASS_NAME_RE

        constantizer = self.constantizer class_name

        define_belongs_to_id_getter name
        define_belongs_to_id_setter name

        define_belongs_to_getter name, constantizer
        define_belongs_to_setter name, constantizer
      end

    private

      def define_belongs_to_id_getter(name)
        attr_reader :"#{name}_id"
      end

      def define_belongs_to_id_setter(name)
        define_method :"#{name}_id=" do |id|
          if id.nil?
            instance_variable_set :"@#{name}_id", nil
            instance_variable_set :"@#{name}",    nil
            break
          end

          raise TypeError, "Expected ID to be a #{String}" unless id.is_a? String
          raise ArgumentError, %(Can not set #{self.class}##{name}id to #{id.inspect} because it contains ":") if id =~ /:/

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
          instance_variable_set :"@#{name}", constantize.().find(::Redis.new, id)
        end
      end

      def define_belongs_to_setter(name, constantize)
        define_method :"#{name}=" do |record|
          if record.nil?
            instance_variable_set :"@#{name}_id", nil
            instance_variable_set :"@#{name}",    nil
            break
          end

          klass = constantize.()

          raise TypeError, "Expected record to be a #{klass}" unless record.is_a? klass

          send :"#{name}_id=", record.id

          send name
        end
      end
    end
  end
end
