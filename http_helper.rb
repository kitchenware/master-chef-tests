
require 'net/http'
require 'uri'

class HttpTester

  include Test::Unit::Assertions

  def initialize vm
    @vm = vm
  end

  def get port, path, user = nil, password = nil, headers = {}
    uri = URI.parse "http://#{@vm.ip}:#{port}#{path}"
    req = Net::HTTP::Get.new(uri.request_uri)

    headers.each do |k, v|
      req[k] = v
    end

    req.basic_auth user, password if user && password

    @response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end

  def post_form port, path, params, user = nil, password = nil, headers = {}
    uri = URI.parse "http://#{@vm.ip}:#{port}#{path}"
    req = Net::HTTP::Post.new(uri.request_uri)

    headers.each do |k, v|
      req[k] = v
    end

    req.set_form_data(params)

    req.basic_auth user, password if user && password

    @response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end

  def extract_set_cookie
    cookie = response['set-cookie']
    assert_not_nil cookie
    assert cookie.length > 0
    cookie
  end

  def assert_last_response_code code
    assert_equal code.to_s, @response.code
  end

  def assert_last_response_body_regex regex
    assert_match regex, @response.body
  end

  def assert_last_response_body_not_regex regex
    assert_not_match regex, @response.body
  end

  def response
    @response
  end

end