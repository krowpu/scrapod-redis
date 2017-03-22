# frozen_string_literal: true

require 'securerandom'

module Scrapod
  module Redis
    class Base
      MODEL_NAME_RE = /\A[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\z/

      def self.model_name
        raise "#{self.class}.model_name has not been set" unless @model_name
        @model_name
      end

      def self.model_name=(s)
        raise TypeError, "expected model name to be a #{String}" unless s.is_a? String
        raise "#{self.class}.model_name has been already set" if @model_name
        raise ArgumentError, "invalid model name #{s.inspect}" unless s =~ MODEL_NAME_RE
        @model_name = s.dup.freeze
      end
    end
  end
end
