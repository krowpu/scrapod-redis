# frozen_string_literal: true

module Scrapod
  module Redis
    module Utils
      NAME_RE = /\A[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\z/
      CLASS_NAME_RE = /\A[A-Z][a-zA-Z0-9]*(::[A-Z][a-zA-Z0-9]*)*\z/

      def constantize(class_name)
        class_name.split('::').inject Object do |namespace, item_name|
          namespace.const_get item_name
        end
      end

      def new_constantizer(class_name)
        raise TypeError, "Expected class name to be a #{String}"        unless class_name.is_a? String
        raise ArgumentError, "Invalid class name #{class_name.inspect}" unless class_name =~ CLASS_NAME_RE

        lambda do
          constantize class_name
        end
      end

      def validate_id(id)
        raise TypeError, "Expected ID to be a #{String}"                         unless id.is_a? String
        raise ArgumentError, %(Blank ID)                                         if id.strip.empty?
        raise ArgumentError, %(Invalid ID #{id.inspect} because it contains ":") if id =~ /:/
      end

      def validate_model_name(name)
        raise TypeError, "Expected model name to be a #{String}"     unless name.is_a? String
        raise ArgumentError, "Model name #{name.inspect} is invalid" unless name =~ Utils::NAME_RE
      end

      def validate_attribute_name(name)
        raise TypeError, "Expected name to be a #{Symbol}"              unless name.is_a? Symbol
        raise ArgumentError, "Invalid association name #{name.inspect}" unless name =~ NAME_RE
      end

      module_function :constantize
      module_function :new_constantizer
      module_function :validate_model_name
      module_function :validate_attribute_name
    end
  end
end
