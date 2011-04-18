module GitPusshuTen
  class Hooks

    ##
    # Contains the environment on the remote server name which
    # is extracted from the selected configuration in the configuration file
    attr_accessor :environment

    ##
    # Contains the configuration object
    attr_accessor :configuration

    ##
    # Contains an array of GitPusshuTen::Hook objects for the current environment
    attr_accessor :to_perform

    ##
    # Contains an array of commands to run for the currently parsed hook
    # This gets reset to [] every time a new hook is being parsed
    attr_accessor :commands_to_run

    ##
    # Initializes a new Hooks object
    # Provide the environment (e.g. :staging, :production) to parse
    def initialize(environment, configuration)
      @environment     = environment
      @configuration   = configuration
      @to_perform      = []
      @commands_to_run = []
    end

    ##
    # Parses the configuration file and loads all the
    # configuration values into the GitPusshuTen::Configuration instance
    def parse!(hooks_file)
      if File.exist?(hooks_file)
        instance_eval(File.read(hooks_file))
      else
        GitPusshuTen::Log.warning "Could not locate the hooks.rb file."
      end
      self
    end

    ##
    # Parses any modules that are set in the configuration (config.rb) file
    def parse_modules!
      configuration.additional_modules.each do |additional_module|
        module_file = File.join(File.dirname(__FILE__), 'modules', additional_module.to_s, 'hooks.rb')
        if File.exist?(module_file)
          instance_eval(File.read(module_file))
        end
      end
      self
    end

    ##
    # Perform On
    # Helper method used to configure the hooks.rb file
    def perform_on(*environments, &configuration)
      if environments.flatten.include?(environment)
        configuration.call
      end
    end

    ##
    # Pre
    # A method for setting pre-hooks inside the perform_on block
    # Resets the "commands_to_run" variable to an empty array so that
    # there's a clean array to work with the next set of commands.
    # The "commands.call" invokes all the "run(<command>)" the user
    # provided in the hooks.rb configuration file and extracts the strings
    # of commands to run. This array is then passed into a newly made Hook object
    # which is again stored into the "to_perform" array.
    def pre(name, &commands)
      @commands_to_run = []
      commands.call
      @to_perform << Hook.new({
        :type     => :pre,
        :name     => name,
        :commands => commands_to_run
      })
    end

    ##
    # Post
    # A method for setting post-hooks inside the perform_on block
    # Resets the "commands_to_run" variable to an empty array so that
    # there's a clean array to work with the next set of commands.
    # The "commands.call" invokes all the "run(<command>)" the user
    # provided in the hooks.rb configuration file and extracts the strings
    # of commands to run. This array is then passed into a newly made Hook object
    # which is again stored into the "to_perform" array.
    def post(name, &commands)
      @commands_to_run = []
      commands.call
      @to_perform << Hook.new({
        :type     => :post,
        :name     => name,
        :commands => commands_to_run
      })
    end

    ##
    # Run
    # A method for setting commands on a
    # post-hook or pre-hook inside the perform_on block
    def run(command)
      @commands_to_run << command
    end

    ##
    # Pre Hooks
    # Returns an array of pre-hooks
    def pre_hooks
      @to_perform.map do |hook|
        next unless hook.type.eql? :pre
        hook
      end.compact
    end

    ##
    # Post Hooks
    # Returns an array of post-hooks
    def post_hooks
      @to_perform.map do |hook|
        next unless hook.type.eql? :post
        hook
      end.compact
    end

    ##
    # Takes an array of hooks and renders them a Hash that
    # contains the name of the hook, as well as all the commands
    # bundled in a single string, separated by semi-colons.
    #
    # Note: Using a hack to avoid "Hash" sorting issues between Ruby versions
    # which cause the hooks to invoke in the incorrect order. This has been addressed
    # by prefixing the Hash's "key" with the index of the array and sorting based on that.
    # Then the \d+\)\s gets #sub'd for friendly user output 
    def render_commands(hooks)
      hooks_hash = {}
      
      hooks.each_with_index do |hook, index|
        hooks_hash["#{index}) #{hook.name}"] = ''
        hook.commands.each do |command|
          hooks_hash["#{index}) #{hook.name}"] += "#{command};".gsub(/;{2,}/, ';')
        end
      end
      
      hooks_hash
    end

  end
end