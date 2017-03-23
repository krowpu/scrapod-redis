# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Process < Base
      self.model_name = 'process'

      datetime :started_at, null: false
    end
  end
end
