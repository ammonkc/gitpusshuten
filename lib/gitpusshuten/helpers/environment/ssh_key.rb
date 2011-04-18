module GitPusshuTen
  module Helpers
    module Environment
      module SSHKeys

        ##
        # USERS
        ##
        # Returns true or false, based on whether the (local) ssh
        # key has been installed on the remote server or not
        def ssh_key_installed?
          return false unless has_ssh_key?
          return true if authorized_ssh_keys.include?(ssh_key)
          false
        end

        ##
        # Returns true or false, based on whether the (local) ssh key exists
        def has_ssh_key?
          File.exist?(ssh_key_path)
        end

        ##
        # Reads out the ssh key file contents
        def ssh_key
          File.read(ssh_key_path)
        end

        ##
        # Connects to the server to read out the ~/.ssh/authorized_keys
        def authorized_ssh_keys
          execute_as_root("cat '#{File.join(home_dir, '.ssh', 'authorized_keys')}'")
        end

        ##
        # Returns the default (local) SSH key path
        def ssh_key_path
          File.join(ENV['HOME'], '.ssh', c.ssh_key || 'id_rsa.pub')
        end

        ##
        # Installs the ssh key on the remote server
        def install_ssh_key!
          command  = "mkdir -p '#{File.join(home_dir, '.ssh')}';"
          command += "echo '#{ssh_key}' >> '#{File.join(home_dir, '.ssh', 'authorized_keys')}';"
          command += "chown -R #{c.user}:#{c.user} '#{File.join(home_dir, '.ssh')}';"
          command += "chmod 700 '#{File.join(home_dir, '.ssh')}'; chmod 600 '#{File.join(home_dir, '.ssh', 'authorized_keys')}'"
          execute_as_root(command)
        end

        ##
        # ROOT
        ##
        # Checks to see if the user's key is already installed in the authorized keys
        # of the root user on the remote server
        def root_ssh_key_installed?
          return false unless has_ssh_key?
          return true if authorized_root_ssh_keys.include?(ssh_key)
          false
        end

        ##
        # Returns a list of authorized keys for the root user
        def authorized_root_ssh_keys
          execute_as_root("cat $HOME/.ssh/authorized_keys")
        end

        ##
        # Installs the user's SSH key in root's authorized keys file
        def install_root_ssh_key!
          command  = "mkdir -p $HOME/.ssh; echo '#{ssh_key}' >> $HOME/.ssh/authorized_keys;"
          command += "chmod 700 $HOME/.ssh; chmod 600 $HOME/.ssh/authorized_keys"
          execute_as_root(command)
        end

      end
    end
  end
end
