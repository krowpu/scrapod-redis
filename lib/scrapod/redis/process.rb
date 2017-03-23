# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Process < Base
      self.model_name = 'process'

      datetime :started_at

      def as_json
        {
          'started_at' => started_at&.to_i,
        }
      end
    end
  end
end
