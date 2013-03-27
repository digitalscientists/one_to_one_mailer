module OneToOneMailer
  module RelatedItems
    class << self

      def user_facets user
        Tire.search INDEX, :size => 100 do
          query do
            boolean do
              must { term :user_id, user.id }
              must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
            end
          end

          facet('categories'){ terms :categories }
          facet('colors'){ terms :colors }
          facet('brands'){ terms :brand }
          facet('sizes'){ terms :size }
        end
      end

      def request_related_products params, user
        popular_items = popular_product_ids(params, user)
        Tire.search INDEX, :type => 'products', :size => 50 do
         q = query do
            boolean do
              must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
              must { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] } if params[:brands].any?
              should { terms :sizes, params[:sizes] } if params[:sizes].any?
            end
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => popular_items}}, :boost_factor => 1.3 } }
          ) if popular_items.any?
          q
        end
      end

      def request_related_questions params, user
        popular_items = popular_question_ids(params, user)
        Tire.search INDEX, :type => 'questions', :size => 30 do
         q = query do
            boolean do
              must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
              must { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => popular_items}}, :boost_factor => 1.3 } }
          ) if popular_items.any?
          q
        end
      end

      def request_related_rateups params, user
        Tire.search INDEX, :type => 'rateup', :size => 30 do
         q = query do
            boolean do
              must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
              must { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end.to_hash
          q
        end
      end

      def popular_product_ids params, user
        pop = Tire.search INDEX, :type => 'question_product_view' do
          query do
            boolean do
              must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
              must { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end

          facet('popularity') { terms :item_id, :size => 100 }
        end

        popularity = pop.results.facets['popularity']['terms']


        if popularity.any?
          hits = ('9' * (popularity.first['count'].to_s.length - 1)).to_i
          popularity.select{ |t| t['count'].to_i >= hits }.map{ |t| t['term'] }.flatten.uniq
        else
          []
        end
      end

      def popular_question_ids params, user
        pop = Tire.search INDEX, :type => 'question_view' do
          query do
            boolean do
              must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
              must { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end

          facet('popularity') { terms :item_id, :size => 100 }
        end

        popularity = pop.results.facets['popularity']['terms']


        if popularity.any?
          hits = ('9' * (popularity.first['count'].to_s.length - 1)).to_i
          popularity.select{ |t| t['count'].to_i >= hits }.map{ |t| t['term'] }.flatten.uniq
        else
          []
        end
      end

      def for_user user
        facets = user_facets user
        params = {
          :categories => facets.results.facets['categories']['terms'].map{|t| t['term']},
          :colors => facets.results.facets['colors']['terms'].map{|t| t['term']},
          :brands => facets.results.facets['brands']['terms'].map{|t| t['term']},
          :sizes => facets.results.facets['sizes']['terms'].map{|t| t['term']}
        }

        products = request_related_products(params, user).results.to_a.uniq(&:original_image_url)[0...6]
        questions = request_related_questions(params, user).results
        rateups = request_related_rateups(params, user).results

        if rateups.size < 6
          questions = questions[0...(12 - rateups.size)]
        elsif questions.size < 6
          rateups = rateups[0...(12 - questions.size)]
        else
          rateups = rateups[0...6]
          questions = questions[0...6]
        end


        {
          :products => OneToOneMailer::Product.read(products),
          :questions => OneToOneMailer::Question.read(questions),
          :rateups => OneToOneMailer::Rateup.read(rateups),
          :categories => params[:categories]
        }
      end

    end
  end
end
