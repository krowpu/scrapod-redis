# frozen_string_literal: true

require 'json'
require 'securerandom'

require 'scrapod/redis/belongs_to'
require 'scrapod/redis/conn'
require 'scrapod/redis/id'
require 'scrapod/redis/utils'

module Scrapod
  module Redis
    class Base
      include Id
      include Conn
      include BelongsTo

      def self.model_name
        raise "#{self}.model_name has not been set" if @model_name.nil?
        @model_name
      end

      def self.model_name=(value)
        raise "#{self}.model_name has already been set" unless @model_name.nil?

        raise TypeError, "Expected model name to be a #{String}" unless value.is_a? String
        raise ArgumentError, "Model name #{value.inspect} is invalid" unless value =~ Utils::NAME_RE

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
