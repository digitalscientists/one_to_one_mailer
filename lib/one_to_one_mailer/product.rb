module OneToOneMailer
  class Product
    def self.read es_results, include_questions=true
      products = es_results.map { |product| new product }
      if include_questions
        load_questions products
      end
      products
    end

    def self.load_questions products
      product_ids = products.map(&:id)
      raw_questions = Tire.search INDEX, :type => 'questions' do
        query do
          terms :product_ids, product_ids
        end
        sort { by :created_at, 'desc' }
      end.results

      products.each do |product|
        raw_question = raw_questions.select { |rc| rc.product_ids.include? product.id }.first
        product.instance_variable_set('@question', OneToOneMailer::Question.new(raw_question)) unless raw_question.nil?
      end

    end

    def initialize raw
      @raw = raw
    end

    def image_variants
      @raw.image_variants
    end

    def user_id
      @raw.user_id
    end

    def original_image_url
      @raw.original_image_url
    end

    def base_url
      @raw.base_url
    end

    def description
      @raw.title
    end

    def id
      @raw.item_id
    end

    def user_id
      @raw.user_id
    end

    def user_name
      @raw.user_name
    end

    def user_avatar_url
      @raw.user_avatar_url
    end

    def question
      item_id = @raw.item_id
      if @question.nil?
        raw_question = Tire.search INDEX, :type => 'questions' do
          query do
            term :product_ids, item_id
          end
          sort { by :created_at, 'desc' }
        end.results.first
        @question = raw_question.present? ? OneToOneMailer::Question.new(raw_question) : nil
      else
        @question
      end
    end


  end
end


