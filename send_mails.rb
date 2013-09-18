app_root = File.dirname(__FILE__)
require File.expand_path(app_root + '/lib/one_to_one_mailer.rb')

ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.asset_host = OneToOneMailer::HOST
ActionMailer::Base.smtp_settings = OneToOneMailer::SMTP_SETTINGS

User = Struct.new :item_id, :email

def get_users page = 1
  Tire.search(OneToOneMailer::INDEX, :type => 'user') do
    filter :exists, :field => :email
    size 100
    from 100*page
  end.results
end



i = 1
users = get_users(i)

while users.size > 0
  users.each do |raw_user|
    user = OneToOneMailer::User.new raw_user
    user.send_mail if user.should_send_mail?
    p user.email
  end
  users = get_users(i)
  i += 1
end
