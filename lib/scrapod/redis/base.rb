# frozen_string_literal: true

require 'json'
require 'securerandom'

module Scrapod
  module Redis
    class Base
      NAME_RE = /\A[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\z/

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

        raise %(Can not set #{self.class}#id to #{value.inspect} because if contains ":") if value =~ /:/

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
