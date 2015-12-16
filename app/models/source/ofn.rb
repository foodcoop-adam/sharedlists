class Source::OFN
  include HTTParty
  base_uri ENV['OFN_URL']

  def self.enabled?
    ENV['OFN_URL'].present?
  end

  def initialize(token = nil)
    @token = token || ENV['OFN_TOKEN']
  end

  def enterprises(q = {}, page: 1, per_page: 100)
    r = self.class.get('/api/enterprises', query: query_for({q: q, page: page, per_page: per_page}))
    r.parsed_response
  end

  def products(q = {}, page: 1, per_page: 100)
    r = self.class.get('/api/products', query: query_for({q: q, page: page, per_page: per_page}))
    r.parsed_response
  end

  def each_product(q = {}, &block)
    paginate(->(page){ products(q, page: page)}) do |r|
      (r['products']||[]).each {|p| block.call(p)}
    end
  end

  def self.to_supplier(data)
    Supplier.new(
      name: data['name'],
      email: data['email'],
      address: (data['owner']['shipping_address'] || data['owner']['bill_address'] rescue nil),
      url: "#{base_uri}/producers/#{data['permalink']}",
      source: "ofn",
      source_number: data['id']
    )
  end

  def self.to_product_attributes_list(data)
    data['variants'].map do |variant|
      {
        number: "#{data['id']}-#{variant['id']}",
        name: variant['name'],
        note: data['description'],
        price: variant['price'],
        # @todo get unit and unit_quantity
        unit: 'piece',
        unit_quantity: 1,
        quantity: variant['count_on_hand'],
        # @todo category: from taxon_ids
        # @todo manufacturer: add producer to ofn api
        # @todo origin: origin from manufacturer
        # @todo tax: add vat to ofn
        # @todo link to variant / product (need to add to model)
      }
    end
  end

  private

  def query_for(q)
    {token: @token}.merge(q)
  end

  def paginate(api_block)
    page = 1
    count = 0
    begin
      r = api_block.call(page)
      count += r['count']
      yield r
      page += 1
    end while r['current_page'] < r['pages']
    count
  end
end
