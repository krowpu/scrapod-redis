# frozen_string_literal: true

require 'redis'

module Scrapod
  module Redis
    module Conn
      attr_reader :conn

      def conn=(value)
        raise "#{self.class}#conn has been already set" unless @conn.nil?

        raise TypeError, "Expected conn to be a #{::Redis}" unless value.is_a? ::Redis

        @conn = value
      end
    end
  end
end
