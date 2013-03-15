module OneToOneMailer
  module RelatedItems
    class << self

      def user_facets user_id
        Tire.search INDEX, :size => 100 do
          query { term :user_id, user_id}

          facet('categories'){ terms :categories }
          facet('colors'){ terms :colors }
          facet('brands'){ terms :brand }
          facet('sizes'){ terms :size }
        end
      end

      def request_related_products params
        recent_items = recent_product_ids(params)
        popular_items = popular_product_ids(params)
        Tire.search INDEX, :type => 'products', :size => 30 do
         q = query do
            boolean do
              should { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] } if params[:brands].any?
              should { terms :sizes, params[:sizes] } if params[:sizes].any?
            end
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => popular_items}}, :boost_factor => 1.3 } }
          ) if popular_items.any?
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => recent_items}}, :boost_factor => 1.2 } }
          ) if recent_items.any?
          q
        end
      end

      def request_related_questions params
        recent_items = recent_question_ids(params)
        popular_items = popular_question_ids(params)
        Tire.search INDEX, :type => 'questions', :size => 30 do
         q = query do
            boolean do
              should { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => popular_items}}, :boost_factor => 1.3 } }
          ) if popular_items.any?
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => recent_items}}, :boost_factor => 1.2 } }
          ) if recent_items.any?
          q
        end
      end

      def request_related_rateups params
        recent_items = recent_rateup_ids(params)
        Tire.search INDEX, :type => 'rateup', :size => 30 do
         q = query do
            boolean do
              should { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end.to_hash
          q[:query][:bool][:should].push(
            { :custom_boost_factor => 
              { :query => {:terms => {:item_id => recent_items}}, :boost_factor => 1.2 } }
          ) if recent_items.any?
          q
        end
      end

      def popular_product_ids params
        pop = Tire.search INDEX, :type => 'question_product_view' do
          query do
            boolean do
              should { terms :categories, params[:categories] }
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

      def popular_question_ids params
        pop = Tire.search INDEX, :type => 'question_view' do
          query do
            boolean do
              should { terms :categories, params[:categories] }
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

      def recent_product_ids params
        r = Tire.search INDEX, :type => 'question_product_view' do
          query do
            boolean do
              must { range :performed_at, {:gte => (Time.now - 1.week).strftime('%Y%m%dT%H%M%SZ')} }
              should { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end
        end.results
        r.map { |document| document.item_id }
      end

      def recent_rateup_ids params
        r = Tire.search INDEX, :type => 'rateup' do
          query do
            boolean do
              must { range :performed_at, {:gte => (Time.now - 1.week).strftime('%Y%m%dT%H%M%SZ')} }
              should { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
              should { terms :brand, params[:brands] }
              should { terms :sizes, params[:sizes] }
            end
          end
        end.results
        r.map { |document| document.item_id }
      end

      def recent_question_ids params
        r = Tire.search INDEX, :type => 'questions' do
          query do
            boolean do
              must { range :created_at, {:gte => (Time.now - 1.week).strftime('%Y%m%dT%H%M%SZ')} }
              should { terms :categories, params[:categories] }
              should { terms :colors, params[:colors] }
            end
          end
        end.results
        r.map { |document| document.item_id }
      end

      def for_user user_id
        facets = user_facets user_id
        params = {
          :categories => facets.results.facets['categories']['terms'].map{|t| t['term']},
          :colors => facets.results.facets['colors']['terms'].map{|t| t['term']},
          :brands => facets.results.facets['brands']['terms'].map{|t| t['term']},
          :sizes => facets.results.facets['sizes']['terms'].map{|t| t['term']}
        }

        products = request_related_products(params).results.to_a.uniq(&:original_image_url)
        questions = request_related_questions(params).results
        rateups = request_related_rateups(params).results

        if products.size < 10
          questions = questions[0...(20 - products.size)]
        elsif questions.size < 10
          products = products[0...(20 - questions.size)]
        else
          products = products[0...10]
          questions = questions[0...10]
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
