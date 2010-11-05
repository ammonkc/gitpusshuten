require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helpers', 'push'))

module GitPusshuTen
  module Commands
    class Branch < GitPusshuTen::Commands::Base
      include GitPusshuTen::Helpers::Push
      
      description "Pushes the specified branch to a remote environment."
      usage       "push branch <branch> to <environment>"
      example     "push branch develop to staging"
      example     "push branch master to production"

      ##
      # Branch specific attributes/arguments
      attr_accessor :branch

      ##
      # Initializes the Branch command
      def initialize(*objects)
        super
        perform_hooks!
        
        @branch = cli.arguments.shift
        
        help if branch.nil? or environment.name.nil?
        
        confirm_remote!
      end

      ##
      # Performs the Branch command
      def perform!
        GitPusshuTen::Log.message "Pushing branch #{branch.to_s.color(:yellow)} to the #{environment.name.to_s.color(:yellow)} environment."
        git.push(:branch, branch).to(environment.name)
      end

    end
  end
end