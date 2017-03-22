# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Process < Base
      self.model_name = 'process'

      attr_reader :started_at

      def initialize(*)
        super

        @started_at ||= nil
      end

      def started_at=(value)
        @started_at = value.nil? ? nil : Time.at(value)
      end

      def as_json
        {
          'started_at' => started_at&.to_i,
        }
      end
    end
  end
end
