require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf5 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf5
    @vm.upload_json "conf5.json"
    @vm.run_chef
    
    # Check sonar
    wait "Waiting sonar init", 300, 10 do
      @http.get 80, "/sonar/sessions/new?return_to=%2Fsonar%2F"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /Login/
    end
  
    # Check nexus
    wait "Waiting nexus init", 300, 10 do
      @http.get 80, "/nexus/index.html#welcome"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /Sonatype Nexus/
    end
  end

end