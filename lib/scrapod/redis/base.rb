# frozen_string_literal: true

require 'json'
require 'securerandom'

require 'scrapod/redis/attributes'
require 'scrapod/redis/belongs_to'
require 'scrapod/redis/has_many'
require 'scrapod/redis/utils'

module Scrapod
  module Redis
    class Base
      include Utils
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

      def self.attributes
        @attributes ||= {}
      end

      def self.belongs_to_associations
        @belongs_to_associations ||= {}
      end

      def self.has_many_associations # rubocop:disable Style/PredicateName
        @has_many_associations ||= {}
      end

      def self.datetime(name, null: true)
        validate_attribute_name name

        attribute = attributes[name] = Attributes::Datetime.new null: null

        define_attribute_getter name
        define_attribute_setter name, attribute
      end

      def self.define_attribute_getter(name)
        attr_reader name
      end

      def self.define_attribute_setter(name, attribute)
        define_method :"#{name}=" do |value|
          instance_variable_set :"@#{name}", attribute.typecast(value)
        end
      end

      def self.belongs_to(name, class_name, inverse_of, null: true)
        validate_attribute_name name

        association = belongs_to_associations[name] = BelongsTo.new class_name, inverse_of, null: null

        attributes[:"#{name}_id"] = association.attribute

        define_belongs_to_id_getter name
        define_belongs_to_id_setter name

        define_belongs_to_getter name, association
        define_belongs_to_setter name, association

        define_belongs_to_nullifier name
      end

      def self.has_many(name, class_name, inverse_of) # rubocop:disable Style/PredicateName
        validate_attribute_name name

        has_many_associations[name] = HasMany.new class_name, inverse_of
      end

      def self.define_belongs_to_id_getter(name)
        attr_reader :"#{name}_id"
      end

      def self.define_belongs_to_id_setter(name)
        define_method :"#{name}_id=" do |id|
          break send :"nullify_#{name}" if id.nil?

          validate_id id

          result = instance_variable_set :"@#{name}_id", id.dup.freeze
          instance_variable_set :"@#{name}", nil

          result
        end
      end

      def self.define_belongs_to_getter(name, association)
        define_method name do
          result = instance_variable_get :"@#{name}"
          break result if result
          id = instance_variable_get :"@#{name}_id"
          break if id.nil?
          instance_variable_set :"@#{name}", association.constantizer.().find(conn, id)
        end
      end

      def self.define_belongs_to_setter(name, association)
        define_method :"#{name}=" do |record|
          break send :"nullify_#{name}" if record.nil?

          klass = association.constantizer.()

          raise TypeError, "Expected record to be a #{klass}" unless record.is_a? klass

          send :"#{name}_id=", record.require_id

          send name
        end
      end

      def self.define_belongs_to_nullifier(name)
        define_method :"nullify_#{name}" do
          instance_variable_set :"@#{name}_id", nil
          instance_variable_set :"@#{name}",    nil
        end
      end

      def self.create(conn, options = {})
        new(options.merge(conn: conn)).save
      end

      def self.find(conn, id)
        validate_id id

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

      def initialize(options = {})
        @id = nil
        @conn = nil

        self.conn = options.delete :conn

        if options.key? :id
          @persisted = true
          self.id = options.delete :id
        else
          @persisted = false
          @id = nil
        end

        options.each do |k, v|
          send :"#{k}=", v
        end
      end

      def save
        raise RecordInvalidError unless valid?

        @id = SecureRandom.uuid.freeze

        conn.multi do
          conn.set "#{self.class.model_name}:id:#{id}", as_json.to_json
          conn.sadd "#{self.class.model_name}:all", id
        end

        @persisted = true

        self
      end

      def destroy
        conn.multi do
          conn.del "#{self.class.model_name}:id:#{require_id}"
          conn.srem "#{self.class.model_name}:all", require_id
        end

        @persisted = false
        @id = nil
      end

      def persisted?
        @persisted
      end

      attr_reader :id

      def require_id
        raise RecordNotPersistedError if @id.nil? || !persisted?
        @id
      end

      def id=(value)
        raise "#{self.class}#id has been already set to #{@id.inspect}" unless @id.nil?

        validate_id value

        @id = value.dup.freeze
      end

      def as_json
        self.class.attributes.map do |name, attribute|
          [
            name.to_s,
            attribute.serialize(send(name)),
          ]
        end.to_h
      end

      def valid?
        self.class.attributes.all? do |name, attribute|
          attribute.validate send(name), conn
        end
      end

    private

      attr_reader :conn

      def conn=(value)
        raise "#{self.class}#conn has been already set" unless @conn.nil?

        raise TypeError, "Expected conn to be a #{::Redis}" unless value.is_a? ::Redis

        @conn = value
      end

      class Error < RuntimeError
      end

      class RecordInvalidError < Error
      end

      class RecordNotPersistedError < Error
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
