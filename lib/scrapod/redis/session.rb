# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Session < Base
      self.model_name = 'session'

      belongs_to :process, 'Scrapod::Redis::Process', null: false

      datetime :started_at, null: false
    end
  end
end
