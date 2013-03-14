module OneToOneMailer
  class Mailer < ActionMailer::Base
    default from: "1to1@rately.com"


    def related_products_mail user
      related = RelatedItems.for_user(user.item_id)

      products = related[:products] + related[:questions].map{|q| q.products}.flatten.uniq{|p| p.id}

      scope = EmailData.new products[0...20]
      mail(:to => user.email, :subject => "Looks from Rately. Featuring: #{related[:categories].join(', ')}") do |format|
        format.html do
          render :text => Slim::Template.new('/Users/admin/Sites/one_to_one_mailer/lib/one_to_one_mailer/mailer/related_products_mail.html.slim', :disable_escape => true).render(scope)
        end
      end
    end
  end


    class EmailData < Struct.new(:products)
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
    end
end
