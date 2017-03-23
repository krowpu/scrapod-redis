# frozen_string_literal: true

require 'scrapod/redis/utils'

module Scrapod
  module Redis
    class HasMany
      include Utils

      attr_reader :me, :class_name, :inverse_of

      def initialize(me, class_name, inverse_of)
        self.me = me
        self.class_name = class_name
        self.inverse_of = inverse_of
      end

      def constantizer
        @constantizer ||= new_constantizer class_name
      end

      def klass
        @klass ||= constantize class_name
      end

      def inverse
        @inverse ||= klass.belongs_to_associations[inverse_of]
      end

    private

      def me=(value)
        raise TypeError, "Expected me to be a #{Class}" unless value.is_a? Class
        @me = value
      end

      def class_name=(value)
        validate_class_name value
        @class_name = value.dup.freeze
      end

      def inverse_of=(value)
        validate_attribute_name value
        @inverse_of = value.to_sym
      end
    end
  end
end
