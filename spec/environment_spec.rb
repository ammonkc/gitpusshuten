require 'spec_helper'

describe GitPusshuTen::Environment do
  
  let(:cli)                { GitPusshuTen::CLI.new(%w[tag 1.4.2 to staging])                             }
  let(:configuration_file) { File.expand_path(File.dirname(__FILE__) + '/fixtures/config.rb')            }
  let(:configuration)      { GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file) }  
  let(:environment)        { GitPusshuTen::Environment.new(configuration)                                }
  let(:ssh)                { mock('ssh')                                                                 }
  
  it "should initialize based on the provided configuration" do
    environment.configuration.should be_an_instance_of(GitPusshuTen::Configuration)
  end
  
  describe 'methods executing as root' do
    it "should use the user specified instead of root when using sudo" do
      configuration.use_sudo = true
      Net::SSH.expects(:start).with(configuration.ip, configuration.user, {:password => configuration.password,
                                                                           :passphrase => configuration.passphrase,
                                                                           :port => configuration.port}).yields(ssh)

      ssh.expects(:exec!).with("sudo su - -c 'ls'")
      environment.execute_as_root('ls')
    end

    it "should leave the user and command unmodified when not using sudo" do
      Net::SSH.expects(:start).with(configuration.ip, 'root', {:password => nil,
                                                               :passphrase => configuration.passphrase,
                                                               :port => configuration.port}).yields(ssh)

      ssh.expects(:exec!).with("ls")
      environment.execute_as_root('ls')
    end
  end

  describe '#app_dir' do
    it "should be the <path>/<application>.<environment>" do
      environment.app_dir.should == '/var/apps/rspec_staging_example_application.staging'
    end
  end
  
  describe '#name' do
    it "should return the name of the environment we're working in" do
      environment.name.should == :staging
    end
  end
  
  describe '#delete!' do
    it "should delete the application root" do
      environment.expects(:execute_as_user).with('rm -rf /var/apps/rspec_staging_example_application.staging')
      environment.delete!
    end
  end
  
  describe 'the ssh methods' do
    describe '#authorized_ssh_keys' do
      it do
        environment.expects(:execute_as_root).with("cat '/var/apps/.ssh/authorized_keys'")
        environment.authorized_ssh_keys
      end
    end
    
    describe '#install_ssh_key!' do
      it do
        environment.expects(:ssh_key).returns('mysshkey')
        environment.expects(:execute_as_root).with("mkdir -p '/var/apps/.ssh';echo 'mysshkey' >> '/var/apps/.ssh/authorized_keys';chown -R git:git '/var/apps/.ssh';chmod 700 '/var/apps/.ssh'; chmod 600 '/var/apps/.ssh/authorized_keys'")
        environment.install_ssh_key!
      end
    end
  end
  
  describe '#download_packages!' do
    it "should download the gitpusshuten packages" do
      environment.expects(:execute_as_user).with("cd /var/apps/; git clone git://github.com/meskyanichi/gitpusshuten-packages.git")
      environment.download_packages!('/var/apps/')
    end
  end
  
  describe '#clean_up_packages!' do
    it "should delete them as root" do
      environment.expects(:execute_as_user).with("cd /var/apps; rm -rf gitpusshuten-packages")
      environment.clean_up_packages!('/var/apps')
    end
  end
end
