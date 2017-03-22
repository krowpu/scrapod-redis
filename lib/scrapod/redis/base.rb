# frozen_string_literal: true

require 'json'
require 'securerandom'

module Scrapod
  module Redis
    class Base
      NAME_RE = /\A[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\z/
      CLASS_NAME_RE = /\A[A-Z][a-zA-Z0-9]*(::[A-Z][a-zA-Z0-9]*)*\z/

      def self.model_name
        raise "#{self}.model_name has not been set" if @model_name.nil?
        @model_name
      end

      def self.model_name=(value)
        raise "#{self}.model_name has already been set" unless @model_name.nil?

        raise TypeError, "Expected model name to be a #{String}" unless value.is_a? String
        raise ArgumentError, "Model name #{value.inspect} is invalid" unless value =~ NAME_RE

        @model_name = value.dup.freeze
      end

      def self.create(conn, options = {})
        new(options).save conn
      end

      def self.find(conn, id)
        json = conn.get "#{model_name}:id:#{id}"
        raise RecordNotFoundError.new(model_name, id) if json.nil?
        options = JSON.parse json
        new options.merge! id: id
      end

      def self.all(conn)
        conn.smembers("#{model_name}:all").map do |id|
          find conn, id
        end
      end

      def self.belongs_to(name, class_name)
        raise TypeError, "Expected name to be a #{Symbol}"              unless name.is_a? Symbol
        raise ArgumentError, "Invalid association name #{name.inspect}" unless name =~ NAME_RE

        raise TypeError, "Expected class name to be a #{String}"        unless class_name.is_a? String
        raise ArgumentError, "Invalid class name #{class_name.inspect}" unless class_name =~ CLASS_NAME_RE

        constantize = self.constantize class_name

        attr_reader :"#{name}_id"

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

        define_method name do
          result = instance_variable_get :"@#{name}"
          break result if result
          id = instance_variable_get :"@#{name}_id"
          break if id.nil?
          instance_variable_set :"@#{name}", constantize.().find(::Redis.new, id)
        end

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

      def self.constantize(class_name)
        lambda do
          class_name.split('::').inject Object do |namespace, item_name|
            namespace.const_get item_name
          end
        end
      end

      def initialize(options = {})
        options.each do |k, v|
          send :"#{k}=", v
        end

        id
      end

      def save(conn)
        conn.multi do
          conn.set "#{self.class.model_name}:id:#{id}", as_json.to_json
          conn.sadd "#{self.class.model_name}:all", id
        end
        self
      end

      def destroy(conn)
        conn.multi do
          conn.del "#{self.class.model_name}:id:#{id}"
          conn.srem "#{self.class.model_name}:all", id
        end
      end

      def id
        @id ||= SecureRandom.uuid.freeze
      end

      def id=(value)
        raise "#{self.class}#id has been already set to #{@id.inspect}" unless @id.nil?

        raise TypeError, "Expected ID to be a #{String}" unless value.is_a? String
        raise ArgumentError, %(Can not set #{self.class}#id to #{value.inspect} because it contains ":") if value =~ /:/

        @id = value.dup.freeze
      end

      class Error < RuntimeError
      end

      class RecordNotFoundError < Error
        attr_reader :model_name, :id

        def initialize(model_name, id)
          @model_name = model_name
          @id = id

          super "Can not find #{model_name} with ID #{id}"
        end
      end
    end
  end
end
