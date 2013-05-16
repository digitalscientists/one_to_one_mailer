module OneToOneMailer
  class User
    def initialize raw
      @raw = raw
    end

    def subscribtion
      @raw.subscribtion
    end

    def id
      @raw.id
    end

    def email
      @raw.email
    end

    def mail_sent_at
      @raw.email_sent_at
    end

    def subscribed?
      !subscribtion.nil? && subscribtion != 'Never'
    end

    def subscribtion_period
      case subscribtion
        when 'Daily' then 1.day
        when 'Weekly' then 1.week
        when 'Monthly' then 1.month
      end
    end

    def should_send_mail?
      subscribed? && (mail_sent_at.nil? || Date.today >= (DateTime.parse(mail_sent_at) + subscribtion_period).to_date) && has_related_items?
    end

    def send_mail
      OneToOneMailer::Mailer.related_products_mail(self).deliver
      user_id = id
      Tire.index(OneToOneMailer::INDEX) do
        update :user, user_id, :doc => {:email_sent_at => Time.now.strftime('%Y%m%dT%H%M%SZ')}
      end
    end

    def related_items
      @related_items ||= RelatedItems.for_user self
    end

    def has_related_items?
      related_items[:products].any? || related_items[:rateups].any? || related_items[:questions].any?
    end

  end
end
