# frozen_string_literal: true

module Scrapod
  module Redis
    module Attributes
      class Base
        attr_reader :null

        def initialize(null: true)
          @null = !!null
        end

        def validate(value, _conn)
          return false if value.nil? && !null
          true
        end

        def typecast(_value)
          raise NotImplementedError, "#{self.class}#typecast not yet implemented"
        end

        def serialize(_value)
          raise NotImplementedError, "#{self.class}#serialize not yet implemented"
        end
      end

      class Integer < Base
        def typecast(value)
          return       if value.nil?
          return value if value.is_a? ::Integer

          result = value.to_i
          raise TypeError unless result.is_a? ::Integer
          result
        end

        def serialize(value)
          value
        end
      end

      class ForeignKey < Integer
        attr_reader :constantizer

        def initialize(constantizer = nil)
          self.constantizer = constantizer
        end

        def null
          !constantizer
        end

        def validate(value, conn)
          return true if null

          return false if value.nil?

          model = constantizer.()

          raise TypeError, "Expected model to be a #{Class}"    unless model.is_a? Class
          raise TypeError, 'Expected model to respond to #find' unless model.respond_to? :find

          begin
            model.find conn, value
          rescue
            return false
          end

          true
        end

      private

        def constantizer=(value)
          return @constantizer = nil if value.nil?

          raise TypeError, 'Expected constantizer to respond to #call' unless value.respond_to? :call
          @constantizer = value
        end
      end

      class Datetime < Base
        def typecast(value)
          return                 if value.nil?
          return value           if value.is_a? ::Time
          return ::Time.at value if value.is_a?(::Integer) || value.is_a?(::Float)
          raise TypeError
        end

        def serialize(value)
          value&.to_i
        end
      end
    end
  end
end
