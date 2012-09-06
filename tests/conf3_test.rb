require File.join(File.dirname(__FILE__), '..', 'helper.rb')
require 'json'

class TestConf3 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf3
    @vm.upload_json "conf3.json"
    @vm.run_chef

    # check redmine
    @http.get 80, "/redmine"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Redmine/
    date = @vm.capture("date -u && date").split("\n").map{|x| x =~ /^.*(\d\d:\d\d:\d\d).*$/; $1}
    assert_not_equal date[0], date[1]

    # wait elastic search
    wait "elastic search http port open", 30, 5 do
      @vm.run("sudo netstat -nltp | grep 127.0.0.1:9300")
    end

    # check kibana
    @http.get 80, '/kibana/loader2.php?page=3'
    @http.assert_last_response_code 200
    json = JSON.parse @http.response.body
    total = json['total']

    @vm.run "\"echo 'abcd' >> /tmp/toto.log\""

    wait "Waiting data in kibana", 30, 5 do
      @http.get 80, '/kibana/loader2.php?page=3'
      @http.assert_last_response_code 200
      json = JSON.parse @http.response.body

      assert_equal json['total'], total + 1
    end

  end

end