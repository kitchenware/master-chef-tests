require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf5 < Test::Unit::TestCase

  include VmTestHelper

  def test_conf5
    @vm.upload_json "conf5.json"
    @vm.run_chef
    @vm.wait_tcp_port @vm.read_chef_local_storage("tomcat:control_port:sonar"), 300, 10
    @http.get 80, "/sonar/sessions/new?return_to=%2Fsonar%2F"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Login/

    @vm.wait_tcp_port @vm.read_chef_local_storage("tomcat:control_port:nexus"), 300, 10
    @http.get 80, "/nexus/index.html#welcome"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Sonatype Nexus/
  end

end