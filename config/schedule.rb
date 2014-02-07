# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
every 1.day do
  command "cd #{ File.expand_path(File.dirname(__FILE__) + "/../send_mails.rb")} && bundle exec ruby send_mails.rb staging"
end

every 1.day do
  command "cd #{ File.expand_path(File.dirname(__FILE__) + "/../send_mails.rb")} && bundle exec ruby send_mails.rb production"
end

every :day, :at => '03:00am' do
  pk = File.expand_path(File.dirname(__FILE__) + "/keys/pk-ZQOTEBVBV2J6MHNGJQOX45RU7I3HYQYG.pem")
  cert = File.expand_path(File.dirname(__FILE__) + "/keys/cert-ZQOTEBVBV2J6MHNGJQOX45RU7I3HYQYG.pem")
  command "source /home/ubuntu/.bashrc; /usr/local/ec2-api-tools-1.6.11.0/bin/ec2-create-snapshot -K #{pk} -C #{cert} vol-b26fb1c2"
end

