require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf6 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf6
    @vm.upload_json "conf6.json"
    @vm.run_chef

    exec_local "cd #{File.join(File.dirname(__FILE__), "..", "nodejs_app_test")} && TARGET=#{@vm.ip} cap deploy"

    @http.get 12345, "/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Hello World/
  end

end