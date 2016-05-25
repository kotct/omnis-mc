require 'json'

require 'omnis-mc/logger'

require 'omnis-mc/default_configuration'
require 'omnis-mc/argument_configuration'
require 'omnis-mc/minecraft_configuration'
require 'omnis-mc/slack_configuration'

require 'omnis-mc/slack_bridge'

module Omnis
	module MC

		class Executor
			def initialize(argv = ARGV)
				@default_configuration = DefaultConfiguration.new
				@argument_configuration = ArgumentConfiguration.new(argv)
				@configuration = @default_configuration.merge(@argument_configuration)

				@slack_configuration ||= SlackConfiguration.new(@configuration[:slack_configuration]) if @configuration[:slack_configuration] && File.readable?(@configuration[:slack_configuration])
				@minecraft_configuration ||= MinecraftConfiguration.new(@configuration[:minecraft_configuration]) if @configuration[:minecraft_configuration] && File.readable?(@configuration[:minecraft_configuration])
			end

			def run
				time_initial = Time.now

				slack_token = @slack_configuration["slack"]["oauth"]["client_id"]
				slack_bridge = SlackBridge.new(slack_token)

				LOGGER.info('Executor#run') do "Successfully started a SlackBridge with token #{slack_token}" end

				minecraft_stdin_fifo = File.expand_path(@minecraft_configuration['minecraft']['stdin_fifo'], File.dirname(@configuration[:minecraft_configuration]))
				minecraft_stdout_fifo = File.expand_path(@minecraft_configuration['minecraft']['stdout_fifo'], File.dirname(@configuration[:minecraft_configuration]))

				minecraft_stdout_fifo = IO.popen("tail -f -n0 '#{File.expand_path minecraft_stdout_fifo}'", 'r')
				minecraft_stdin_fifo = open(minecraft_stdin_fifo, 'w')

				LOGGER.info('Executor#run') do "Starting slack_thread" end

				slack_thread = Thread.new do |slack_thread|
					slack_time_initial = Time.now

					slack_bridge.web_api_method_call('api.test', {'token' => slack_token}) do |response, parsed_response|
						if parsed_response['ok']
							LOGGER.debug('slack_thread') do "/api/api.test was successful" end
						else
							LOGGER.error('slack_thread') do "/api/api.test was not successful" end
						end
					end

					LOGGER.info('slack_thread') do "Starting RTM loop after #{Time.now - slack_time_initial}s" end
					slack_bridge.rtm_start! minecraft_stdin_fifo
					LOGGER.error('slack_thread') do "SlackBridge's RTM loop failed! What?" end
				end

				LOGGER.info('Executor#run') do "Starting typing_thread" end

				typing_thread = Thread.new do |typing_thread|
					loop do
						line = gets.chomp

						begin
							slack_bridge.rtm_send_message!('C18MUUEJY', line)
						rescue
						end
					end
				end

				LOGGER.info('Executor#run') do "Starting minecraft_thread" end

				minecraft_thread = Thread.new do |minecraft_io_thread|
					loop do
						read, write, error = IO.select([minecraft_stdout_fifo])

						if read.include?(minecraft_stdout_fifo)
							message = minecraft_stdout_fifo.gets

							LOGGER.info('minecraft_thread') do message.chomp end

							text = nil

							case message
							when /\[Server thread\/(INFO)\]\: (.+) joined the game/
								text = "User `#{$2}` joined."
							when /\[Server thread\/(INFO)\]\: (.+) left the game/
								text = "User `#{$2}` left."
							when /\[Server thread\/(INFO)\]\: <(.+)> (.+)/
								text = "<`#{$2}`> #{$3}"
							else
								LOGGER.info('minecraft_thread') do "Not sending Slack message for unknown message type." end
							end

							slack_bridge.rtm_send_message!('C18MUUEJY', text) if text
						end
					end
				end

				LOGGER.info('Executor#run') do "Started all threads after #{Time.now-time_initial}s" end

				minecraft_thread.join
				typing_thread.kill
				slack_thread.kill
			end
		end

	end
end
