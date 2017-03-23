# frozen_string_literal: true

require 'scrapod/redis/attributes'
require 'scrapod/redis/utils'

module Scrapod
  module Redis
    class BelongsTo
      include Utils

      attr_reader :class_name, :inverse_of, :null

      def initialize(class_name, inverse_of: nil, null: true)
        self.class_name = class_name
        self.inverse_of = inverse_of
        self.null = null
      end

      def attribute
        @attribute ||= Attributes::ForeignKey.new null ? nil : constantizer
      end

      def constantizer
        @constantizer ||= new_constantizer class_name
      end

      def klass
        @klass ||= constantize class_name
      end

    private

      def class_name=(value)
        validate_class_name value
        @class_name = value.dup.freeze
      end

      def inverse_of=(value)
        return @inverse_of = nil if value.nil?

        validate_attribute_name value
        @inverse_of = value.to_sym
      end

      def null=(value)
        @null = !!value
      end
    end
  end
end