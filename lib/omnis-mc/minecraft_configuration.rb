require 'yaml'
require 'omnis-mc/configuration'

module Omnis
	module MC

		class MinecraftConfiguration < Configuration
			def initialize(filename)
				@filename = filename

				read_and_parse!
			end

			def read!
				read(@filename)
			end

			def read_and_parse!
				merge!(parse(read(@filename)))
			end

			protected

			def read(filename)
				open(filename, 'rb') do |io|
					io.read
				end
			end

			def parse(data)
				YAML.load(data).to_h
			end
		end

	end
end
