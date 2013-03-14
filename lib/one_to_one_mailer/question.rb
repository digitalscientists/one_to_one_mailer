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
      raw_products = Tire.search INDEX, :type => 'products', :size => product_ids.size do
        query do
          terms :item_id, product_ids
        end
      end.results.to_a
      questions.each do |question|
        raw_question_products = raw_products.select {|rp| question.raw.product_ids.include? rp.item_id.to_s }
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
      @raw.item_id
    end

    def to_param
      "#{@raw.slug}-#{id}" 
    end

    def owner_id
      @raw.owner_id
    end

    def owner_name
      @raw.owner_name
    end

    def owner_avatar_url
      @raw.owner_avatar_url
    end

    def products
      product_ids = @raw.product_ids
      if @products.nil?
        raw_products = Tire.search INDEX, :type => 'products' do
          query do
            terms :item_id, product_ids#.first
          end
        end.results
        @products = Product.read(raw_products)
      else
        @products
      end
    end

    

  end
end

