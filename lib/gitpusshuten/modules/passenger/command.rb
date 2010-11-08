module GitPusshuTen
  module Commands
    class Passenger < GitPusshuTen::Commands::Base
      description "Invoke various passenger commands on the remote server."
      usage       "passenger <command> for <environment>"
      example     "passenger restart for staging"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Tag command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or environment.name.nil?
      end

      ##
      # Performs the Passenger command
      def perform!
        GitPusshuTen::Log.message "Restarting Passenger for #{app_name} (#{environment_name} environment)."
        environment.execute_as_user("cd #{environment.app_dir}; mkdir -p tmp; touch tmp/restart.txt")
      end

    end
  end
end