require 'spec_helper'

describe GitPusshuTen::Command do
    
  let(:cli)           { mock('cli')           }
  let(:configuration) { mock('configuration') }
  let(:hooks)         { mock('hooks')         }
  let(:environment)   { mock('environment')   }
  
  before do
    cli.stubs(:command).returns('non_existing_command')
    configuration.stubs(:additional_modules).returns([])
  end
  
  it "should error out if the command was not found" do
    GitPusshuTen::Log.expects(:error).with("Command <non_existing_command> not found.")
    GitPusshuTen::Command.any_instance.expects(:exit)
    
    GitPusshuTen::Command.new(cli, configuration, hooks, environment)
  end
  
  describe '#available_commands' do
    it "should display available commands without the .rb extension" do
      GitPusshuTen::Command.any_instance.stubs(:exit)
      GitPusshuTen::Log.stubs(:error)
      
      command = GitPusshuTen::Command.new(cli, configuration, hooks, environment)
      command.expects(:commands_directory).returns([Dir.pwd + '/commands/mock_tag.rb'])
      command.available_commands.should include('mock_tag')
    end
    
    it "should not include the base command" do
      GitPusshuTen::Command.any_instance.stubs(:exit)
      GitPusshuTen::Log.stubs(:error)
      
      command = GitPusshuTen::Command.new(cli, configuration, hooks, environment)
      command.expects(:commands_directory).returns(Dir[File.expand_path(File.dirname(__FILE__) + '/../lib/gitpusshuten/commands/*.rb')])
      command.available_commands.should_not include('base')
    end
  end
  
  it "should initialize the specified command" do
    GitPusshuTen::Command.any_instance.stubs(:exit)
    GitPusshuTen::Log.stubs(:error)
    
    GitPusshuTen::Commands::NonExistingCommand.expects(:new).with(cli, configuration, hooks, environment)
    
    command = GitPusshuTen::Command.new(cli, configuration, hooks, environment)
    command.stubs(:commands_directory).returns([Dir.pwd + '/commands/mock_tag.rb'])
    command.command
  end
  
  describe "executed as root" do
    let(:command_initializer) { GitPusshuTen::Command.new(cli, configuration, hooks, environment) }
    let(:command)             { command_initializer.command }

    before do
      cli.stubs(:command).returns('non_existing_root_command')
      GitPusshuTen::Command.any_instance.stubs(:exit)
      GitPusshuTen::Log.stubs(:error)
      command.stubs(:validate!)
    end

    it "should ask for the root password" do
      environment.expects(:execute_as_root).with('')
      command_initializer.perform!
    end
  end

  describe "perform hooks" do
    let(:command_initializer) { GitPusshuTen::Command.new(cli, configuration, hooks, environment) }
    let(:command)             { command_initializer.command }
    
    before do
      GitPusshuTen::Command.any_instance.stubs(:exit)
      GitPusshuTen::Log.stubs(:error)
      command.stubs(:validate!)
    end
    
    it "should invoke a pre-perform hook" do
      command.expects(:pre_perform!).once
      command.stubs(:post_perform!)
      command_initializer.perform!
    end
    
    it "should invoke a post-perform hook" do
      command.expects(:post_perform!).once
      command.stubs(:pre_perform!)
      command_initializer.perform!
    end
  end
  
end