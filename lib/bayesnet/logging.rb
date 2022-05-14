# lib/logging.rb

module Bayesnet
  def self.logger
    @logger ||= Logger.new(STDOUT).tap { |l| l.level = :debug }
  end

  module Logging
    def logger
      Bayesnet.logger
    end
  end
end
