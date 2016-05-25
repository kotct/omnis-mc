require 'json'
require 'net/http'
require 'eventmachine'
require 'addressable/uri'
require 'faye/websocket'

require 'omnis-mc/logger'

require 'pp'

module Omnis
	module MC

		class SlackBridge
			BASE_URI = "https://slack.com/api/"

			attr_reader :token, :ws, :rtm_data, :rtm_url, :user_id

			def initialize(token)
				@token = token

				authenticate!
			end

			def authenticated?
				!!@auth_status
			end

			def authenticate!
				web_api_method_call('auth.test', {'token' => @token}) do |response, parsed_response|
					@auth_status = parsed_response['ok'] || nil

					LOGGER.debug('SlackBridge#authenticate!') do (@auth_status ? "Authenticated." : "Not authenticated!") end
				end
			end

			def web_api_method_call(method, params, &block)
				query_string = Addressable::URI.new
				query_string.query_values = params

				uri = URI.join(BASE_URI, method + "?" + query_string.query)

				Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |transport|
					request = Net::HTTP::Get.new uri

					response = transport.request(request)

					parsed_response = nil

					begin
						parsed_response = JSON.parse(response.body)
					rescue JSON::ParserError => e
						puts e
					end

					block.call(response, parsed_response)
				end
			end

			def rtm_send_message!(channel_id, text)
				@rtm_id ||= 0

				payload = {
					id: @rtm_id,
					type: :message,
					channel: channel_id,
					text: text
				}

				if @ws
					data = JSON.generate(payload)
					@ws.send data

					LOGGER.debug('SlackBridge#rtm_send_message!') do "Sent message of length #{data.length}" end
				end

				@rtm_id += 1
			end

			def rtm_start! minecraft_stdin_fifo
				web_api_method_call('rtm.start', {'token' => @token}) do |response|
					@rtm_data = JSON.parse(response.body)
					@rtm_status = :pre_fetched
					@rtm_url = @rtm_data['url']

					LOGGER.debug('SlackBridge#rtm_start!') do "Got successful response from #{response.uri.host}, will use RTM WS url of #{@rtm_url}" end
				end

				LOGGER.debug('SlackBridge#rtm_start!') do "Building user cache" end

				users = {}

				web_api_method_call('users.list', {'token' => @token}) do |response|
					data = JSON.parse(response.body)

					members = data['members']

					members.select do |user|
						!user['deleted']
					end.each do |user|
						users[user['id']] = user['name']
					end
				end

				LOGGER.debug('SlackBridge#rtm_start!') do "Have #{users.keys.count} users in the cache" end

				LOGGER.debug('SlackBridge#rtm_start!') do "Starting EM loop" end


				EventMachine.run do
					@ws = Faye::WebSocket::Client.new(@rtm_url)

					@ws.on :open do |event|
						@rtm_status = :open
					end

					@ws.on :message do |event|
						object = JSON.parse(event.data)

						case type = object['type']
						when 'hello'
						when 'presence_change'
						when 'reconnect_url'
						when 'message'
							text = object['text']
							sender = object['user']

							sender = users[sender] || 'unknown'

							LOGGER.debug('EM.run (ws)') do "Received message from Slack (sender: #{sender})" end

							object = [{"text" => "[Slack:#{sender}] ", "color" => "gold", "italic" => false, "bold" => true}, {"text" => text, "color" => "gray", "italic" => true, "bold" => false}]

							command = "tellraw @a #{JSON.generate(object)}"

							LOGGER.debug('EM.run (ws)') do "Running command #{command}" end

							minecraft_stdin_fifo.puts command
							begin
								minecraft_stdin_fifo.fsync
							rescue NotImplementedError => e
								e.backtrace.each do |element|
									Logger.error('EM.run (ws) write') do element end
								end

								minecraft_stdin_fifo.flush
							end

							LOGGER.debug('EM.run (ws)') do "Command completed successfully" end
						else
							LOGGER.warn('EM.run (ws)') do "Unknown message type #{type.inspect}" end
						end
					end

					@ws.on :close do |event|
						@rtm_status = :closed
					end
				end
			end
		end
	end
end
