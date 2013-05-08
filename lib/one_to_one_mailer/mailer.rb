require 'digest/sha1'
module OneToOneMailer
  class Mailer < ActionMailer::Base


    def related_products_mail user
      scope = EmailData.new user
      mail(
        :from => 'Rately <support@rately.com>',
        :to => user.email, 
        :subject => "Looks from Rately. Featuring: #{user.related_items[:categories].join(', ')}") do |format|
        format.html do
          render :text => Slim::Template.new(File.join(File.dirname(__FILE__), 'mailer', 'related_products_mail.html.slim'), :disable_escape => true).render(scope)
        end
      end
    end
  end


    class EmailData < Struct.new(:user)
      def products
        user.related_items[:products]
      end
      def rateups
        user.related_items[:rateups]
      end
      def questions
        user.related_items[:questions]
      end
      def question_path question, opts = {}
        path = "#{HOST}/questions/#{question.to_param}"
        path += "##{opts[:anchor]}"if opts[:anchor]
        path
      end

      def users_questions_path user_name, user_id
        "#{HOST}/stream/#{user_name}-#{user_id}"
      end

      def link_to path 
        %Q{<a href="#{path}"> #{yield} </a>}.html_safe
      end

      def include_stylesheets
        stylesheets = {
          :development => %w{
            user_stream_n_lists_common.css
            stream.css
            stream-mobile.css
          },
          :staging => %w{stream},
          :production => %w{stream}
        }[OneToOneMailer.env]
        stylesheets.map do |stylesheet|
          %Q{<link href="#{HOST}/stylesheets/#{stylesheet}" media="screen" rel="stylesheet" type="text/css">}
        end.join.html_safe
      end

      def email_token
        Digest::SHA1.hexdigest "#{user.email}ratelysalt"
      end

      def unsubscribe_url
        "#{HOST}/users/unsubscribe_related_items?email=#{user.email}&token=#{email_token}"
      end

      def settings_url
        "#{HOST}/settings"
      end
    end
end
