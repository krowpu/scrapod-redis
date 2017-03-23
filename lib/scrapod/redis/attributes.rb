# frozen_string_literal: true

module Scrapod
  module Redis
    module Attributes
      class Datetime
        attr_reader :null

        def initialize(null: true)
          @null = !!null
        end

        def validate(value)
          return false if value.nil? && !null
          true
        end

        def typecast(value)
          return               if value.nil?
          return value         if value.is_a? Time
          return Time.at value if value.is_a?(Integer) || value.is_a?(Float)
          raise TypeError
        end

        def serialize(value)
          value&.to_i
        end
      end
    end
  end
end
