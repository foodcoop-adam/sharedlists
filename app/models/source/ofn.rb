class Source::OFN
  include HTTParty
  base_uri ENV['OFN_URL']

  def self.enabled?
    ENV['OFN_URL'].present? && ENV['OFN_EMAIL'].present?
  end

  def initialize(email = nil, password = nil)
    @email = email || ENV['OFN_EMAIL'] || 'spree@example.com'
    @password = password || ENV['OFN_PASSWORD'] || 'spree123'
    @csrf_token = nil
    @cookie = CookieHash.new
    login
  end

  def enterprises(query = {})
    r = self.class.get('/admin/enterprises.json', query: query, headers: headers)
    r.parsed_response
  end

  def enterprises_for_order_cycle(query)
    r = self.class.get('/admin/enterprises/for_order_cycle', query: query, headers: headers)
    r.parsed_response
  end

  def self.to_supplier(data)
    @supplier = Supplier.new(
      name: data['name'],
      email: data['email'],
      address: data['owner']['shipping_address'] || data['owner']['bill_address'],
      url: "#{base_uri}/producers/#{data['permalink']}",
      source: "ofn",
      source_number: data['id']
    )
  end

  private

  def login
    # get login form
    r = self.class.get('/user/spree_user/sign_in')
    if r.body =~ /<input name="authenticity_token".*? value="(.*?)".*?>/
      @csrf_token = $1
      Rails.logger.debug "OFNSupplier login: got CSRF token '#{@csrf_token}'"
    else
      Rails.logger.warn "OFNSupplier login: did not get CSRF token"
    end
    @cookie = parse_cookie(r.headers)
    Rails.logger.debug "OFNSupplier login: got cookie '#{@cookie}' (GET)"
    # submit
    r = self.class.post('/user/spree_user/sign_in', body: {
      spree_user: {
        email: @email,
        password: @password
      },
    }, headers: headers)
    # retrieve cookie
    @cookie = parse_cookie(r.headers)
    Rails.logger.debug "OFNSupplier login: got cookie '#{@cookie}' (POST)"
  end

  def parse_cookie(resp)
    (resp.get_fields('Set-Cookie') || []).each { |c| @cookie.add_cookies(c) }
    @cookie
  end

  def headers
    h = {}
    h['Accept'] = 'application/json'
    if @csrf_token
      h['X-Requested-With'] = 'XMLHTTPRequest'
      h['X-CSRF-Token'] = @csrf_token
    end
    h['Cookie'] = @cookie.to_cookie_string if @cookie
    h
  end

end
