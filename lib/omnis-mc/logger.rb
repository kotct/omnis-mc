require 'logger'

module Omnis

	module MC

		class Logger < ::Logger
			def initialize(*arguments)
				super(*arguments)

				@formatter = proc do |severity, time, prog, msg|
					"#{'%8s' % [severity]} (#{time.strftime('%m-%d %H:%M:%S %Z')}) <#{prog}> #{msg}\n"
				end
			end
		end

		LOGGER = MC::Logger.new(STDOUT)
		LOGGER.level = ::Logger::DEBUG

	end

end
