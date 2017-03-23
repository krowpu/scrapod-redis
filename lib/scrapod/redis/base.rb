# frozen_string_literal: true

require 'json'
require 'securerandom'

require 'scrapod/redis/utils'

module Scrapod
  module Redis
    class Base
      extend Utils

      def self.model_name
        raise "#{self}.model_name has not been set" if @model_name.nil?
        @model_name
      end

      def self.model_name=(value)
        raise "#{self}.model_name has already been set" unless @model_name.nil?
        validate_model_name value
        @model_name = value.dup.freeze
      end

      def self.create(conn, options = {})
        new(options.merge(conn: conn)).save
      end

      def self.find(conn, id)
        json = conn.get "#{model_name}:id:#{id}"
        raise RecordNotFoundError.new(model_name, id) if json.nil?
        options = JSON.parse json
        new options.merge! id: id, conn: conn
      end

      def self.all(conn)
        conn.smembers("#{model_name}:all").map do |id|
          find conn, id
        end
      end

      def self.belongs_to(name, class_name)
        validate_attribute_name name

        constantizer = new_constantizer class_name

        define_belongs_to_id_getter name
        define_belongs_to_id_setter name

        define_belongs_to_getter name, constantizer
        define_belongs_to_setter name, constantizer

        define_belongs_to_nullifier name
      end

      def self.define_belongs_to_id_getter(name)
        attr_reader :"#{name}_id"
      end

      def self.define_belongs_to_id_setter(name)
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

      def self.define_belongs_to_getter(name, constantizer)
        define_method name do
          result = instance_variable_get :"@#{name}"
          break result if result
          id = instance_variable_get :"@#{name}_id"
          break if id.nil?
          instance_variable_set :"@#{name}", constantizer.().find(conn, id)
        end
      end

      def self.define_belongs_to_setter(name, constantizer)
        define_method :"#{name}=" do |record|
          break send :"nullify_#{name}" if record.nil?

          klass = constantizer.()

          raise TypeError, "Expected record to be a #{klass}" unless record.is_a? klass

          send :"#{name}_id=", record.id

          send name
        end
      end

      def self.define_belongs_to_nullifier(name)
        define_method :"nullify_#{name}" do
          instance_variable_set :"@#{name}_id", nil
          instance_variable_set :"@#{name}",    nil
        end
      end

      def initialize(options = {})
        options.each do |k, v|
          send :"#{k}=", v
        end

        raise "#{self.class}#conn has not been set" if conn.nil?

        id
      end

      def save
        conn.multi do
          conn.set "#{self.class.model_name}:id:#{id}", as_json.to_json
          conn.sadd "#{self.class.model_name}:all", id
        end
        self
      end

      def destroy
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

      attr_reader :conn

      def conn=(value)
        raise "#{self.class}#conn has been already set" unless @conn.nil?

        raise TypeError, "Expected conn to be a #{::Redis}" unless value.is_a? ::Redis

        @conn = value
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
