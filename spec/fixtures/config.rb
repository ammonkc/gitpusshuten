pusshuten :staging, 'RSpec Staging Example Application' do
  
  authorize do |a|
    a.user      = 'git'
    a.password  = 'testtest'
    a.ip        = '123.45.678.910'
    a.port      = '20'
  end
  
  git do |g|
    g.path = '/var/apps/'
  end
  
  environment do |e|
    e.operating_system = :ubuntu
    e.webserver        = :nginx
    e.webserver_module = :passenger
    e.framework        = :rails
  end
  
  configuration do |c|
    c.perform_deploy_hooks       = true
    c.perform_custom_deploy_hook = true
    
    c.deploy_hooks        -= [:migrate_database]
    c.custom_deploy_hooks -= [:my_custom_deploy_hook]
  end
  
end

pusshuten :production, 'RSpec Production Example Application' do
  
end