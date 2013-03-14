app_root = File.dirname(__FILE__)
require File.expand_path(app_root + '/lib/one_to_one_mailer.rb')

ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.asset_host = OneToOneMailer::HOST
ActionMailer::Base.smtp_settings = OneToOneMailer::SMTP_SETTINGS

ARGV.each do |a|
  puts "Argument: #{a}"
end

puts ARGV[0].inspect

puts OneToOneMailer::SMTP_SETTINGS.inspect

User = Struct.new :item_id, :email

def get_users from = 0
  Tire.search(OneToOneMailer::INDEX, :type => 'users', :size => 100, :from => from) do
    filter :exists, :field => :email
  end.results
  []
end

users = get_users
i = 1
while users.size > 0
  users.each do |user|
    puts "#{user.item_id} - #{user.email}"
    OneToOneMailer::Mailer.related_products_mail(user).deliver
  end
  puts i
  users = get_users(i * 100)
  i += 1
end

%w{kostya.malinovskiy@gmail.com kmalyn@softserveinc.com}.each do |mail|
  OneToOneMailer::Mailer.related_products_mail(User.new('512ccb5b0ca1a106bf00000b', mail)).deliver
end
