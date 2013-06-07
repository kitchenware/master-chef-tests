require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf1 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf1
    @vm.upload_json "conf1.json"
    @vm.run_chef

    # Check confluence
    @http.get 80, "/toto/setup/setuplicense.action"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Confluence Setup Wizard/
    @vm.run "sudo netstat -nltp | grep 127.0.0.1:9999 | grep LISTEN | grep java"
    @vm.run "sudo netstat -nltp | grep 127.0.0.1:3306 | grep LISTEN"

    @vm.run "echo 'pouet\npipo\nmolo\nbidule\nchose\n' > /home/chef/fake.log"
    @vm.run "sudo logrotate -f /etc/logrotate.d/fake"
    rotated_file = @vm.capture("ls /home/chef/fake.log.1")
    assert_equal "/home/chef/fake.log.1\n", rotated_file

    @vm.run "sudo touch /etc/logrotate.d/todelete"
    @vm.run_chef

    files = @vm.capture "ls -1 /etc/logrotate.d/"
    assert_false files.split("\n").include?("todelete")

  end

end