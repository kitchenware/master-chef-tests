require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf1 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf1
    @vm.upload_json "conf1.json"
    @vm.run_chef

    # Check confluence
    wait "waiting confluence init", 60, 5 do
        @http.get 80, "/toto/setup/setuplicense.action"
        @http.assert_last_response_code 200
        @http.assert_last_response_body_regex /Confluence Setup Wizard/
    end
    @vm.run "sudo netstat -nltp | grep 127.0.0.1:9999 | grep LISTEN | grep java"
    @vm.run "sudo netstat -nltp | grep 127.0.0.1:3306 | grep LISTEN"

    # check confluence crowd integration
    @vm.run "sudo sed -i 's/false/true/g' /opt/master-chef/etc/local.json"
    # very uggly thing to force chef to resintall confluence with crowd integration
    @vm.run "sudo rm -rf /opt/tomcat && sudo rm -rf /confluence"

    @vm.run_chef
    @vm.run "[ -f /opt/tomcat/instances/confluence/webapps/toto/WEB-INF/lib/crowd-integration-client-2.2.7.jar ]"
    @vm.run "[ -f /opt/tomcat/instances/confluence/webapps/toto/WEB-INF/classes/crowd.properties ]"
    @vm.run "[ -f /opt/tomcat/instances/confluence/webapps/toto/WEB-INF/classes/crowd-ehcache.xml ]"
    @vm.run "cat /opt/tomcat/instances/confluence/webapps/toto/WEB-INF/classes/atlassian-user.xml | grep crowd"

    # test logrotate
    @vm.run "echo 'pouet\npipo\nmolo\nbidule\nchose\n' > /home/chef/fake.log"
    @vm.run "sudo logrotate -f /etc/logrotate.d/fake"
    rotated_file = @vm.capture("ls /home/chef/fake.log.1")
    assert_equal "/home/chef/fake.log.1\n", rotated_file

    # test deleting files in logrotate.d
    @vm.run "sudo touch /etc/logrotate.d/todelete"
    @vm.run_chef

    files = @vm.capture "ls -1 /etc/logrotate.d/"
    assert_false files.split("\n").include?("todelete")

    #memcached
    memory = @vm.capture("cat /etc/memcached.conf | grep 128")
    assert_equal "-m 128\n", memory

    wait "Waiting memcached ready", 30, 5 do
      ok = @vm.capture("echo -e 'flush_all\nquit' | nc localhost 11211")
      assert_equal "OK\r\n", ok
    end

    #redis
    redis_maxclient = @vm.capture("sudo cat /etc/redis/redis.conf | grep maxclients")
    assert_equal "maxclients 128\n", redis_maxclient

    redis_databases = @vm.capture("sudo cat /etc/redis/redis.conf | egrep ^databases")
    assert_equal "databases 16\n", redis_databases

    wait "Waiting redis ready", 30, 5 do
    	pong = @vm.capture("echo -en 'PING\r\nQUIT\r\n' | nc localhost 6379")
    	assert_match /\+PONG/, pong
    end

  end

end
