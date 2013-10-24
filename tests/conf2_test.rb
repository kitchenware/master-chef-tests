require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf2 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf2
    @vm.run "[ -f /my_loop_device_1 ] || sudo dd if=/dev/zero of=/my_loop_device_1 bs=200M count=1"
    @vm.run "[ -f /my_loop_device_2 ] || sudo dd if=/dev/zero of=/my_loop_device_2 bs=20M count=1"
    @vm.run "[ -f /loop0_ok ] || (sudo losetup /dev/loop0 /my_loop_device_1 && sudo touch /loop0_ok)"
    @vm.run "[ -f /loop1_ok ] || (sudo losetup /dev/loop1 /my_loop_device_2 && sudo touch /loop1_ok)"

    @vm.upload_json "conf2.json"
    @vm.run_chef

    # check lvm
    @vm.run "mount | grep vg.storage-lv.data | grep '/jenkins' | grep ext4"
    @vm.run "mount | grep vg.test-lv.test | grep '/toto' | grep ext3"
    @vm.run "echo titi > /toto/tata"

    @http.get 80, "/jenkins/"
    @http.assert_last_response_code 401
    assert_equal @http.response['WWW-Authenticate'], "Basic realm=\"myrealm\", Basic realm=\"myrealm\""
    @http.get 80, "/jenkins/", 'test', 'mypassword'
    assert_not_equal @http.response.code.to_i, 401

    wait "Waiting jenkins init" do
      @http.get 80, "/jenkins/", 'test', 'mypassword'
      @http.assert_last_response_code 200
      @http.assert_last_response_body_regex /New Job/
    end

    @http.get 80, "/jenkins/pluginManager/installed", 'test', 'mypassword'
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Green Balls/

    # Check cron management
    # Check chef second run
    crons = @vm.capture("ls /etc/cron.d").split("\n")
    assert_true crons.include?("munin-update")
    @vm.run "sudo touch /etc/cron.d/a"
    @vm.run_chef
    new_crons = @vm.capture("ls /etc/cron.d").split("\n")
    assert_equal crons, new_crons
    @http.get 80, "/jenkins/", 'test', 'mypassword'
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /New Job/

    # Check APR is loaded into tomcat
    catalina_out = @vm.capture("cat /var/log/tomcat/jenkins/catalina.out")
    assert_not_match /n production environments was not found/, catalina_out

    # Check multiple Java version
    java_version = @vm.capture("java -version 2>&1")
    assert_match /1.7.0_07/, java_version
    @http.get 80, "/jenkins/systemInfo", 'test', 'mypassword'
    @http.assert_last_response_code 200
    assert_match /1\.7\.0_07/, @http.response.body.gsub("<wbr>","")

    # testing ssh_accept_host_key
    @vm.run "ssh-keygen -F localhost"

    # test postgresql is open on 0.0.0.0
    @vm.run "sudo netstat -nltp | grep 0.0.0.0:5432 | grep LISTEN"

    # test postgresql
    @vm.run "PGPASSWORD=mypassword psql --username titi tata --command='SELECT 1;' > /dev/null"
    @vm.run "PGPASSWORD=mypassword psql --host localhost --username titi tata --command='SELECT 1;' > /dev/null"
    @vm.run_fail "PGPASSWORD=mypassword psql --username titi postgres --command='SELECT 1;' > /dev/null"
    @vm.run "sudo psql postgres --command='SELECT 1;' > /dev/null"
    @vm.run "sudo psql tata --command='SELECT 1;' > /dev/null"
    @vm.run "/tmp/wrapper.sh --command='SELECT 1;' > /dev/null"

    # test dbmgr
    @vm.run "/tmp/wrapper.sh --command 'DROP TABLE toto;' || true"
    @vm.run "/tmp/wrapper.sh --command 'DROP TABLE playedsqlscripts;' || true"
    @vm.run "mkdir -p /tmp/toto && echo 'CREATE TABLE toto (c int);' > /tmp/toto/00-create.sql && echo 'INSERT INTO toto (c) VALUES (42);' > /tmp/toto/01-insert.sql"
    @vm.run "/tmp/dbmgr.sh --cmd /tmp/wrapper.sh --version toto --dir /tmp/toto > /tmp/log"
    @vm.run "cat /tmp/log | grep -v 'to run' | grep '^+'"
    @vm.run "/tmp/dbmgr.sh --cmd /tmp/wrapper.sh --version toto --dir /tmp/toto > /tmp/log"
    @vm.run_fail "cat /tmp/log | grep -v 'to run' | grep '^+'"
    @vm.run "echo 'SELECT c FROM toto;' | /tmp/wrapper.sh | grep 42"
  end

end