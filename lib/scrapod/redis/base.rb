# frozen_string_literal: true

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
    end
  end
end
