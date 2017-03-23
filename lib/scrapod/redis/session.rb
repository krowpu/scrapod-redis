# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Session < Base
      self.model_name = 'session'

      belongs_to :process, 'Scrapod::Redis::Process'

      datetime :started_at

      def as_json
        {
          'process_id' => process_id,
          'started_at' => started_at&.to_i,
        }
      end
    end
  end
end
