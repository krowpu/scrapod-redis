# frozen_string_literal: true

require 'scrapod/redis/base'

module Scrapod
  module Redis
    class Session < Base
      self.model_name = 'session'
    end
  end
end
