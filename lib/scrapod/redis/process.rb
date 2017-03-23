# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Process < Base
      self.model_name = 'process'

      has_many :sessions, 'Scrapod::Redis::Session', :process

      datetime :started_at, null: false
    end
  end
end
