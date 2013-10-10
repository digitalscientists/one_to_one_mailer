require 'tire'
require 'uri'
require 'slim'
require 'action_mailer'
require 'active_support/all'
%w{version product question rateup related_items mailer user}.each do |m|
  require File.expand_path(File.dirname(__FILE__) + "/one_to_one_mailer/#{m}.rb")
end

module OneToOneMailer

  def self.env
    (ARGV[0] || 'development').to_sym
  end

  INDEX = {
    :development => 'tracked_activities',
    :staging => 'tracked_activities_staging',
    :production => 'tracked_activities_production'
  }[env]
  HOST = {
    :development => 'http://localhost:8080',
    :staging => 'http://staging.rately.com',
    :production => 'http://rately.com',
  }[env]

  SMTP_SETTINGS = {
    :staging => {
      :address => "localhost", 
      :port => 1025
    },
    :development => {
      :address => "localhost", 
      :port => 1025
    },
    :staging1 => {
      :address   => "smtp.mandrillapp.com",
      :port      => 25, # ports 587 and 2525 are also supported with STARTTLS
      :enable_starttls_auto => true, # detects and uses STARTTLS
      :user_name => "vishi.gondi@digitalscientists.com",
      :password  => "JoLHgr-GxHE5Zs-AEaYMNw", # SMTP password is any valid API key
      :authentication => 'login' # Mandrill supports 'plain' or 'login'
    },
    :production => {
      :address   => "smtp.mandrillapp.com",
      :port      => 25, # ports 587 and 2525 are also supported with STARTTLS
      :enable_starttls_auto => true, # detects and uses STARTTLS
      :user_name => "vishi.gondi@digitalscientists.com",
      :password  => "JoLHgr-GxHE5Zs-AEaYMNw", # SMTP password is any valid API key
      :authentication => 'login' # Mandrill supports 'plain' or 'login'
    }
  }[env]
  # Your code goes here...
  #
end
