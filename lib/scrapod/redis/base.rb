# frozen_string_literal: true

require 'json'
require 'redis'
require 'securerandom'

module Scrapod
  module Redis
    class Base
      MODEL_NAME_RE = /\A[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\z/

      @@conn = nil

      def self.conn
        raise "#{Base}.conn has not been set" unless @@conn
        @@conn
      end

      def self.conn=(conn)
        raise "#{Base}.conn has been already set" if @@conn

        raise TypeError, "expected conn to be a #{::Redis}" unless conn.is_a? ::Redis
        @@conn = conn
      end

      def self.model_name
        raise "#{self}.model_name has not been set" unless @model_name
        @model_name
      end

      def self.model_name=(s)
        raise "#{self}.model_name has been already set" if @model_name

        raise TypeError, "expected model name to be a #{String}" unless s.is_a? String
        raise ArgumentError, "invalid model name #{s.inspect}" unless s =~ MODEL_NAME_RE
        @model_name = s.dup.freeze
      end

      def self.record_key(id)
        raise ArgumentError, %(#{model_name} ID #{id.inspect} contains ":") if id =~ /:/
        "#{model_name}:#{id}"
      end

      def self.find(id)
        json = conn.get record_key id
        raise RecordNotFoundError.new(model_name, id) if json.nil?
        new JSON.parse json
      end

      def initialize(options = {})
        options.each do |k, v|
          send :"#{k}=", v
        end
      end

      class Error < StandardError
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
