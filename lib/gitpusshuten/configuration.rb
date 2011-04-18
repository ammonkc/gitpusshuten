module GitPusshuTen
  class Configuration

    ##
    # Contains the Application's name which is extracted from
    # the selected configuration in the configuration file
    attr_accessor :application

    ##
    # Contains the environment on the remote server name which
    # is extracted from the selected configuration in the configuration file
    attr_accessor :environment

    ##
    # Returns true if the configuration has been found
    attr_accessor :found
    alias :found? :found

    ##
    # Contains the user, password, passphrase, ssh key, ip and port
    # for connecting and authorizing the user to the remote server
    attr_accessor :user, :password, :passphrase, :ssh_key, :ip, :port

    ##
    # Contains the path to where the application should be pushed
    attr_accessor :path

    ##
    # Contains a list of modules
    attr_accessor :additional_modules

    ##
    # A flag to force the parsing
    attr_accessor :force_parse

    ##
    # Configure
    # helper method for the pusshuten configuration method
    def configure
      yield self
    end

    ##
    # Modules
    # Helper method for adding modules
    def modules
      yield self
    end

    ##
    # Modules - Add
    # Helper method for the Modules helper to add modules to the array
    def add(module_object)
      @additional_modules << module_object
    end

    ##
    # Pusshuten
    # Helper method used to configure the configuration file
    def pusshuten(application, *environment, &block)
      environment.flatten!

      environment.each do |env|
        unless env.is_a?(Symbol)
          GitPusshuTen::Log.error 'Please use symbols as environment name.'
          exit
        end
      end

      if environment.include?(@environment) or force_parse
        @application = application
        @found       = true
        block.call
      end
    end

    ##
    # Initializes a new configuration object
    # takes the absolute path to the configuration file
    def initialize(environment)
      @environment = environment
      @found       = false
      @force_parse = false

      @additional_modules = []
    end

    ##
    # Parses the configuration file and loads all the
    # configuration values into the GitPusshuTen::Configuration instance
    def parse!(configuration_file)
      instance_eval(File.read(configuration_file))

      ##
      # If no configuration is found by environment then
      # it will re-parse it in a forced manner, meaning it won't
      # care about the environment and it will just parse everything it finds.
      # This is done because we can then extract all set "modules" from the configuration
      # file and display them in the "Help" screen so users can look up information/examples on them.
      #
      # This will only occur if no environment is found/specified. So when doing anything
      # environment specific, it will never force the parsing.
      if not found? and environment.nil?
        @force_parse = true
        instance_eval(File.read(configuration_file))
        @additional_modules.uniq!
      end

      if not found? and not environment.nil?
        GitPusshuTen::Log.error "Could not find any configuration for #{environment.to_s.color(:yellow)}."
        exit
      end

      ##
      # Default to port 22 if no port is specified
      @port ||= '22'

      self
    end

    ##
    # Returns a (simple) sanitized version of the application name
    def sanitized_app_name
      application.gsub(' ', '_').downcase
    end

  end
end
