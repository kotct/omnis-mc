require 'logger'

module Omnis

	module MC

		Logger = ::Logger.new(STDOUT)
		Logger.level = ::Logger::DEBUG

		Logger.formatter = proc do |severity, time, prog, msg|
			"#{'%8s' % [severity]} (#{time.strftime('%m-%d %H:%M:%S %Z')}) <#{prog}> #{msg}\n"
		end

	end

end
