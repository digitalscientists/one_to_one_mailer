#!/usr/bin/env rake
require "bundler/gem_tasks"

namespace :amazon do
  desc 'Create a snapshot of the EC2 volume'
  task :snapshot => :environment do
    puts "Creating server disk snapshot"
    keys_dir =  File.expand_path(File.dirname(__FILE__) + "/config/keys")
    output = `/usr/local/ec2-api-tools-1.6.11.0/bin/ec2-create-snapshot -K #{keys_dir}/pk-ZQOTEBVBV2J6MHNGJQOX45RU7I3HYQYG.pem -C #{keys_dir}/cert-ZQOTEBVBV2J6MHNGJQOX45RU7I3HYQYG.pem vol-d1ab41bf`
    puts output

    #if $?.exitstatus != 0
    #  HoptoadNotifier.notify(Exception.new("Backup snapshot creation failed: #{output}"))
    #end
  end
end
