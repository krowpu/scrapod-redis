# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Session < Base
      self.model_name = 'session'

      attr_reader :started_at

    private

      def started_at=(i)
        @started_at = Time.at i
      end
    end
  end
end
