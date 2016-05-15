require 'optparse'

require 'omnis-mc/configuration'

module Omnis
	module MC

		class ArgumentConfiguration < Configuration

			def initialize(argv)
				@argv = argv
				parse!
			end

			def parse!
				merge!(parse(@argv))
			end

			protected

			def parse(argv)
				options = {}

				option_parser = OptionParser.new do |_parser|
					_parser.banner = "Usage: #{$0} [OPTIONS]"

					_parser.separator ''
					_parser.separator 'Bot Options:'

					# TODO Add Bot Options

					_parser.separator ''
					_parser.separator 'Web Server Options:'

					# TODO Add Server Options

					_parser.separator ''
					_parser.separator 'Configuration Options:'

					_parser.on '-sPATH', '--slack PATH', 'Load Slack configuration from PATH.' do |path|
						if File.exist?(filename = File.expand_path(path, Dir.pwd))
							options[:slack_configuration] = filename
						else
							raise RuntimeError, "File #{filename.inspect} does not exist!"
						end
					end

					_parser.on '-mPATH', '--minecraft PATH', 'Load Minecraft Server configuration from PATH.' do |path|
						if File.exist?(filename = File.expand_path(path, Dir.pwd))
							options[:minecraft_configuration] = filename
						else
							raise RuntimeError, "File #{filename.inspect} does not exist!"
						end
					end

					_parser.separator ''
					_parser.separator 'Generic Options:'

					_parser.on '-lLEVEL', '--level LEVEL', 'Only log messages above or at level LEVEL' do |level|
						require 'omnis-mc/logger'

						match_data = level.match /(^[defiuw].*$)/i

						if match_data
							first_letter = match_data[1].chars.first

							case first_letter.downcase
							when 'd'
								Logger.level = ::Logger::DEBUG
							when 'e'
								Logger.level = ::Logger::ERROR
							when 'f'
								Logger.level = ::Logger::FATAL
							when 'i'
								Logger.level = ::Logger::INFO
							when 'u'
								Logger.level = ::Logger::UNKNOWN
							when 'w'
								Logger.level = ::Logger::WARN
							else
								raise RuntimeError, "Invalid LEVEL #{level} (this exception should never be reached)."
							end
						else
							raise RuntimeError, "Invalid LEVEL #{level} (RegExp: /(^[defiuw].*$)/i)."
						end
					end

					_parser.on '-h', '--help', 'Prints this usage message and exits.' do
						puts _parser
						exit
					end
				end

				option_parser.parse!(argv)

				options
			end

		end

	end
end
