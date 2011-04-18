require 'FileUtils'
require 'open-uri'
require 'yaml'

require 'rubygems'
require 'bundler/setup' unless @ignore_bundler
require 'active_support/inflector'
require 'net/ssh'
require 'net/scp'
require 'highline/import'
require 'rainbow'
require 'json'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gitpusshuten/**/*'))].each do |file|
  if not File.directory?(file) and not file =~ /\/modules\/.+\/hooks\.rb/
    require file
  end
end

module GitPusshuTen
end
