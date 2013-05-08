module OneToOneMailer
  class Question

    attr_reader :raw

    def self.read es_results, include_products=true
      questions = es_results.map { |question| new question }
      if include_products
        load_products questions
      end
      questions
    end

    def self.load_products questions
      product_ids = questions.map{|q| q.raw.product_ids}.flatten.uniq
      raw_products = Tire.search INDEX, :size => product_ids.size do
        query do
          ids product_ids, 'products'
        end
      end.results.to_a
      questions.each do |question|
        raw_question_products = raw_products.select {|rp| question.raw.product_ids.include? rp.id.to_s }
        products = OneToOneMailer::Product.read raw_question_products, false
        question.instance_variable_set("@products", products)
      end
    end

    def initialize raw
      @raw = raw
    end

    def text
      @raw.text
    end

    def id
      @raw._id
    end

    def to_param
      "#{@raw.slug}-#{id}" 
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

    def products
      product_ids = @raw.product_ids
      if @products.nil?
        raw_products = Tire.search INDEX do
          query do
            ids product_ids, 'products'
          end
        end.results
        @products = Product.read(raw_products)
      else
        @products
      end
    end

    

  end
end

