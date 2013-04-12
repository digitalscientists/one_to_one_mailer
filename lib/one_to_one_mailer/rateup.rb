module OneToOneMailer
  class Rateup
    def self.read es_results, include_questions=true
      rateups = es_results.map { |rateup| new rateup }
      if include_questions
        load_questions rateups
      end
      rateups
    end

    def self.load_questions rateups
      question_ids = rateups.map(&:question_id)
      raw_questions = Tire.search INDEX do
        query do
          ids question_ids, 'questions'
        end
        sort { by :created_at, 'desc' }
      end.results

      rateups.each do |rateup|
        raw_question = raw_questions.select { |rq| rq._id == rateup.question_id }.first
        rateup.instance_variable_set('@question', OneToOneMailer::Question.new(raw_question)) unless raw_question.nil?
      end
    end

    def self.load_products rateups
      product_ids = rateups.map(&:product_id)
      raw_questions = Tire.search INDEX, :type => 'products' do
        query do
          terms :mongo_copy_id, product_ids
        end
        sort { by :created_at, 'desc' }
      end.results

      rateups.each do |rateup|
        raw_product = raw_products.select { |rp| rp.mongo_copy_id == rateup.product_id }.first
        rateup.instance_variable_set('@product', OneToOneMailer::Product.new(raw_product)) unless raw_product.nil?
      end
    end

    def initialize raw
      @raw = raw
    end

    def cdn_image
      product.cdn_image
    end

    def user_id
      @raw.user_id
    end

    def question_id
      @raw.question_id
    end

    def original_image_url
      product.original_image_url
    end

    def base_url
      product.base_url
    end

    def description
      product.description
    end

    def id
      @raw._id
    end

    def product_id
      @raw.product_id
    end

    def user_name
      @raw.user_name
    end

    def user_avatar_url
      @raw.user_avatar_url
    end

    def question
      item_id = @raw.question_id
      if @question.nil?
        raw_question = Tire.search INDEX do
          query do
            ids [item_id], 'questions'
          end
          sort { by :created_at, 'desc' }
        end.results.first
        @question = raw_question.present? ? OneToOneMailer::Question.new(raw_question) : nil
      else
        @question
      end
    end

    def product
      item_id = @raw.product_id
      if @product.nil?
        raw_product = Tire.search INDEX, :type => 'products' do
          query do
            #ids [item_id], 'products'
            term :mongo_copy_id, item_id
          end
          sort { by :created_at, 'desc' }
        end.results.first
        @product = raw_product.present? ? OneToOneMailer::Product.new(raw_product) : nil
      else
        @product
      end
    end


  end
end



