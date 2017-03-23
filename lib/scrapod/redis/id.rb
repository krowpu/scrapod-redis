# frozen_string_literal: true

module Scrapod
  module Redis
    module Id
      def id
        @id ||= SecureRandom.uuid.freeze
      end

      def id=(value)
        raise "#{self.class}#id has been already set to #{@id.inspect}" unless @id.nil?

        raise TypeError, "Expected ID to be a #{String}" unless value.is_a? String
        raise ArgumentError, %(Can not set #{self.class}#id to #{value.inspect} because it contains ":") if value =~ /:/

        @id = value.dup.freeze
      end
    end
  end
end
