require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestJenkins < Test::Unit::TestCase

  include VmTestHelper

  def test_conf2
    @vm.upload_json "conf2.json"
    @vm.run_chef
    ok = false
    (1..20).each do |k|
      @http.get 80, "/jenkins/"
      if @http.response.code == "200" && @http.response.body =~ /New Job/
        ok = true
        break
      end
      puts "Waiting jenkins init"
      sleep 2      
    end
    assert_true ok
    crons = @vm.capture("ls /etc/cron.d").split("\n")
    assert_true crons.include?("munin-update")
    @vm.run "sudo touch /etc/cron.d/a"
    @vm.run_chef
    new_crons = @vm.capture("ls /etc/cron.d").split("\n")
    assert_equal crons, new_crons
    @http.get 80, "/jenkins/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /New Job/
  end

end