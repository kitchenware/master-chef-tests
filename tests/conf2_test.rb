require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf2 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf2
    @vm.upload_json "conf2.json"
    @vm.run_chef
    
    wait "Waiting jenkins init" do
      @http.get 80, "/jenkins/"
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /New Job/
    end
    
    # Check cron management
    # Check chef second run
    crons = @vm.capture("ls /etc/cron.d").split("\n")
    assert_true crons.include?("munin-update")
    @vm.run "sudo touch /etc/cron.d/a"
    @vm.run_chef
    new_crons = @vm.capture("ls /etc/cron.d").split("\n")
    assert_equal crons, new_crons
    @http.get 80, "/jenkins/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /New Job/
    
    # Chef APR
    catalina_out = @vm.capture("cat /var/log/tomcat/jenkins/catalina.out")
    assert_not_match /n production environments was not found/, catalina_out
    
    # Check multiple Java version
    java_version = @vm.capture("java -version 2>&1")
    assert_match /1.7.0_04/, java_version
    @http.get 80, "/jenkins/systemInfo"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /1\.7\.0_04/
  end

end