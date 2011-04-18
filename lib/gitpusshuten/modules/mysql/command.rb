module GitPusshuTen
  module Commands
    class Mysql < GitPusshuTen::Commands::Base
      description "[Module] MySQL installer and manager."
      usage       "mysql <command> <environment>"
      example     "heavenly mysql install on staging                # Installs MySQL to the staging environment."
      example     "heavenly mysql uninstall from staging            # Uninstalls MySQL from the staging environment."
      example     "heavenly mysql add-user to staging               # Adds the user to MySQL on the production environment."
      example     "heavenly mysql remove-user from staging          # Remvoes the user from MySQL on the production environment."
      example     "heavenly mysql change-root-password on staging   # Changes the root password of MySQL on the staging environment."

      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = @command.underscore
      end

      ##
      # Install MySQL
      def perform_install!
        if e.installed?('mysql')
          error "MySQL is already installed."
          exit
        end
        
        message "Please provide a new password for your MySQL database #{y('root')} user."
        prompt_for_new_password!
        
        e.ensure_aptitude_installed!
        
        command  = "export DEBIAN_FRONTEND=noninteractive; aptitude update;"
        command += "aptitude install -y mysql-client mysql-server libmysqlclient15off libmysqlclient15-dev mysql-common;"
        command += "mysqladmin -u root password '#{@new_password}'"
        
        Spinner.return :message => "Installing #{y('MySQL')} to #{y(e.name)}.." do
          e.execute_as_root(command)
          g('Done!')
        end
      end

      ##
      # Changes the root password of the MySQL Server
      def perform_change_root_password!
        if not e.installed?('mysql')
          error "MySQL isn't installed."
          exit
        end
        
        message "Please provide your MySQL #{y('root')} password."
        @existing_password = ask('') { |q| q.echo = false }
        confirm_access!
        
        message "Please provide a new password for your MySQL database #{y('root')} user."
        prompt_for_new_password!
        
        Spinner.return :message => "Changing root password of #{y('MySQL')} on #{y(e.name)} environment.." do
          e.execute_as_root("mysqladmin -u root --password='#{@existing_password}' password '#{@new_password}'")
          g('Done!')
        end
      end

      ##
      # Uninstalls the MySQL server
      def perform_uninstall!
        if not e.installed?('mysql')
          error "MySQL isn't installed."
          exit
        end
        
        message "Please provide your MySQL #{y('root')} password."
        @existing_password = ask('') { |q| q.echo = false }
        confirm_access!
        
        Spinner.return :message => "Uninstalling #{y('MySQL')} from #{y(e.name)} environment.." do
          e.execute_as_root("mysqladmin -u root --password='#{@existing_password}' password ''")
          e.execute_as_root("aptitude remove -y mysql-client mysql-server")
          g('Done!')
        end
      end

      ##
      # Adds the environment user to the database
      def perform_add_user!
        if not e.installed?('mysql')
          error "MySQL isn't installed."
          exit
        end
        
        ##
        # Confirm Root Password
        message "Please provide your MySQL #{y('root')} password."
        @existing_password = ask('') { |q| q.echo = false }
        confirm_access!
        
        ##
        # Ask password for the new user
        message "Please provide a new password for your MySQL database user."
        prompt_for_new_password!
                
        command  = "\"CREATE USER '#{c.user}'@'localhost' IDENTIFIED BY '#{@new_password}';"
        command += "GRANT ALL ON *.* TO '#{c.user}'@'localhost';\""
        
        response = e.execute_as_root("mysql -u root --password='#{@existing_password}' -e #{command}")
        if not response =~ /ERROR 1396/
          message "User #{y(c.user)} has been added!"
        else
          error "User #{y(c.user)} already exists."
        end
        
      end

      ##
      # Removes the user from the database
      def perform_remove_user!
        if not e.installed?('mysql')
          error "MySQL isn't installed."
          exit
        end
        
        ##
        # Confirm Root Password
        message "Please provide your MySQL #{y('root')} password."
        @existing_password = ask('') { |q| q.echo = false }
        confirm_access!
        
        response = e.execute_as_root("mysql -u root --password='#{@existing_password}' -e \"DROP USER '#{c.user}'@'localhost';\"")
        if response =~ /ERROR 1396/
          error "User #{y(c.user)} does not exist."
        elsif response.nil?
          message "User #{y(c.user)} has been removed!"
        else
          puts response
        end
      end

      ##
      # Prompts the user to fill in a new password
      def prompt_for_new_password!
        while not @mysql_new_password_confirmed
          @new_password = ask('') { |q| q.echo = false }
          message "Please enter your password again."
          @password_confirmation = ask('')  { |q| q.echo = false }

          if not @new_password.empty? and @new_password == @password_confirmation
            @mysql_new_password_confirmed = true
          else
            if @new_password.empty? or @password_confirmation.empty?
              error "Please provide a password."
            else
              error "Password and Password confirmation do not match."
            end
          end
        end
      end

      ##
      # Prompts the user to fill in it's existing password
      def prompt_for_existing_password!
        while not @mysql_existing_password_confirmed
          message "Please provide your password for your MySQL database root user."
          @existing_password = ask('') { |q| q.echo = false }
          message "Please enter your password again."
          @password_confirmation = ask('')  { |q| q.echo = false }

          if not @existing_password.empty? and @existing_password == @password_confirmation
            @mysql_existing_password_confirmed = true
          else
            if @existing_password.empty? or @password_confirmation.empty?
              error "Please provide a password."
            else
              error "Password and Password confirmation do not match."
            end
          end
        end
      end

      ##
      # Confirms whether the provided password is correct
      def confirm_access!
        if e.execute_as_root("mysqladmin -u root --password='#{@existing_password}' ping") =~ /Access denied for user/
          error "Incorrect password."
          exit
        end
      end

    end
  end
end