require 'omnis-mc/configuration'

module Omnis
	module MC

		class DefaultConfiguration < Configuration
			def initialize
				set!
			end

			def set!
				merge!(default_configuration)
			end

			protected

			def default_configuration
				{
					slack_configuration: File.expand_path(File.join('..', '..', '..', 'config', 'slack.yml'), __FILE__),
					minecraft_configuration: File.expand_path(File.join('..', '..', '..', 'config', 'minecraft.yml'), __FILE__)
				}
			end
		end

	end
end
