# encoding: utf-8
module GitPusshuTen
  module Commands
    class Initialize < GitPusshuTen::Commands::Base
      description "Initializes Git Pusshu Ten (プッシュ天) with the working directory."
      usage       "initialize"
      example     "heavenly initialize  # Initializes Git Pusshu Ten (プッシュ天) with the working directory."

      ##
      # Initialize specific attributes/arguments
      attr_accessor :working_directory

      ##
      # Incase template files already exist
      attr_accessor :confirm_perform

      def initialize(*objects)
        super
        
        @working_directory = Dir.pwd
        @confirm_perform   = true
      end

      ##
      # Performs the Initialize command
      def perform!
        message "Would you like to initialize Git Pusshu Ten (プッシュ天) with #{working_directory}?"
        if yes?
          copy_templates!
          if not git.initialized?
            git.initialize!
          end
          git.ignore!
        else
          message "If you wish to initialize it elsewhere, please move into that directory and run #{y("heavenly initialize")} again."
        end
      end

      ##
      # Copies the "config.rb" and "hooks.rb" templates over
      # to the .gitpusshuten inside the working directory
      def copy_templates!
        if File.directory?(File.join(working_directory, '.gitpusshuten'))
          warning "Git Pusshu Ten (プッシュ天) is already initialized in #{y(working_directory)}."
          warning "Re-initializing it will cause it to overwrite the current #{y("config.rb")} and #{y("hooks.rb")} files."
          warning "Are you sure you wish to continue?"
          @confirm_perform = yes?
        end
        
        if confirm_perform
          local.execute("mkdir -p '#{working_directory}/.gitpusshuten'")
          Dir[File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'templates', '*.rb'))].each do |template|
            local.execute("cp '#{template}' '#{working_directory}/.gitpusshuten/#{template.split('/').last}'")
          end
          message "Git Pusshu Ten (プッシュ天) initialized in: #{y(working_directory)}!"
        end
      end

    end
  end
end
