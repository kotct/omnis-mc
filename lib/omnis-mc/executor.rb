require 'omnis-mc/default_configuration'
require 'omnis-mc/argument_configuration'

module Omnis
	module MC

		class Executor
			def initialize(argv = ARGV)
				@default_configuration = DefaultConfiguration.new
				@argument_configuration = ArgumentConfiguration.new(argv)
				@configuration = @default_configuration.merge(@argument_configuration)
			end

			def run
				puts @configuration
			end
		end

	end
end
