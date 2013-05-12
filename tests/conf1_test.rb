require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf1 < Test::Unit::TestCase

  include VmTestHelper

  def test_conf1
    @vm.upload_json "conf1.json"
    @vm.run_chef

    # Check confluence
    @http.get 80, "/toto/setup/setuplicense.action"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Confluence Setup Wizard/
    @vm.run "sudo netstat -nltp | grep 127.0.0.1:9999 | grep LISTEN | grep java"
    @vm.run "sudo netstat -nltp | grep 127.0.0.1:3306 | grep LISTEN"
  end

end