# lib/logging.rb

module Bayesnet
  def self.logger
    @logger ||= Logger.new(STDOUT).tap { |l| l.level = :info }
  end

  module Logging
    def logger
      Bayesnet.logger
    end
  end
end
