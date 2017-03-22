# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Session < Base
      self.model_name = 'session'

      attr_reader :active, :started_at

      def initialize(options = {})
        options.each do |k, v|
          send :"#{k}=", v
        end

        id

        @active     ||= false
        @started_at ||= nil
      end

      def active=(value)
        @active = !!value
      end

      def started_at=(value)
        @started_at = value.nil? ? nil : Time.at(value)
      end

      def as_json
        {
          'active'     => active,
          'started_at' => started_at&.to_i,
        }
      end
    end
  end
end
