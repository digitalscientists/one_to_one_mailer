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
          facet('domains'){ terms :domain }
          facet('colors'){ terms :colors }
          facet('brands'){ terms :brand }
          facet('sizes'){ terms :size }
        end
      end

      def request_related_products related_query
        popular_items = popular_product_ids(related_query)
        Tire.search INDEX, :type => 'products', :size => 50 do
         q = query do
            boolean &related_query
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:ids => {:values => popular_items, :type => 'products'}}, :boost_factor => 1.3 } }
          ) if popular_items.any?
          q
        end
      end

      def request_related_questions related_query
        popular_items = popular_question_ids(related_query)
        Tire.search INDEX, :type => 'questions', :size => 30 do
         q = query do
            boolean &related_query
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:ids => {:values => popular_items, :type => 'questions'}}, :boost_factor => 1.3 } }
          ) if popular_items.any?
          q
        end
      end

      def request_related_rateups related_query
        Tire.search INDEX, :type => 'rateup', :size => 30 do
         q = query do
            boolean &related_query
          end.to_hash
          q
        end
      end

      def popular_product_ids related_query
        pop = Tire.search INDEX, :type => 'question_product_view' do
          query do
            boolean &related_query
          end

          facet('popularity') { terms :product_id, :size => 100 }
        end

        popularity = pop.results.facets['popularity']['terms']


        if popularity.any?
          hits = ('9' * (popularity.first['count'].to_s.length - 1)).to_i
          popularity.select{ |t| t['count'].to_i >= hits }.map{ |t| t['term'] }.flatten.uniq
        else
          []
        end
      end

      def popular_question_ids related_query
        pop = Tire.search INDEX, :type => 'question_view' do
          query do
            boolean &related_query
          end

          facet('popularity') { terms :question_id, :size => 100 }
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
          :domain => facets.results.facets['domains']['terms'].map{|t| t['term']},
          :colors => facets.results.facets['colors']['terms'].map{|t| t['term']},
          :brands => facets.results.facets['brands']['terms'].map{|t| t['term']},
          :sizes => facets.results.facets['sizes']['terms'].map{|t| t['term']}
        }

        related_query = lambda do |boolean|
          boolean.must { range :created_at, {:gte => (user.mail_sent_at || (Time.now - user.subscribtion_period).strftime('%Y%m%dT%H%M%SZ'))} }
          boolean.must { terms :categories, params[:categories] }
          boolean.should { terms :domain, params[:domain] }
          boolean.should { terms :colors, params[:colors] }
          boolean.should { terms :brand, params[:brands] }
          boolean.should { terms :sizes, params[:sizes] }
        end

        products = request_related_products(related_query).results.to_a.uniq(&:original_image_url)[0...6]
        questions = request_related_questions(related_query).results
        rateups = request_related_rateups(related_query).results

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
