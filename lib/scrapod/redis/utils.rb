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

      module_function :constantize
      module_function :new_constantizer
    end
  end
end
