require File.join(File.dirname(__FILE__), '..', 'helper.rb')
require 'json'

class TestConf3 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf3
    @vm.upload_json "conf3.json"
    @vm.run_chef

    @vm.run "ls -al /opt/elasticsearch/logs | grep '/var/log/elasticsearch'"

    # check redmine
    @http.get 80, "/redmine"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Redmine/

    # check date
    date = @vm.capture("date -u && date").split("\n").map{|x| x =~ /^.*(\d\d:\d\d:\d\d).*$/; $1}
    assert_not_equal date[0], date[1]

    # check rails app restart
    @vm.run "sudo /etc/init.d/redmine restart"
    @http.get 80, "/redmine"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Redmine/

    # wait elastic search
    wait "Elastic search http port open", 60, 5 do
      @vm.run("sudo netstat -nltp | grep 127.0.0.1:9200")
    end

    # check kibana
    @vm.run "echo 'truc' >> /tmp/toto.log"

    index = nil
    wait "Wait logstash index in elastic search", 180, 5 do
      @http.get 80, "/_aliases"
      @http.assert_last_response_code 200
      json = JSON.parse @http.response.body
      index = json.keys.find{|x| x =~ /logstash/}
      assert index
    end

    s = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
    @vm.run "echo '#{s}' >> /tmp/toto.log"

    wait "Waiting data in elasticsearch", 180, 5 do
      @http.get 80, "/#{index}/_search?q=#{s}"
      @http.assert_last_response_code 200
      json = JSON.parse @http.response.body
      assert_equal json['hits']['total'], 1
    end

    # check kibana 3
    @http.get 80, "/kibana3/config.js"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /window.location.protocol/
    @http.assert_last_response_body_regex /window.location.hostname/

  end

end