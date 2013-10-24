require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf4 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf4
    @vm.upload_json "conf4.json"
    @vm.run_chef

    # check mysql listening
    @vm.run "sudo netstat -nltp | grep 0.0.0.0:3306 | grep LISTEN"

    # check mysql config
    @vm.run "echo 'SELECT 1;' | mysql --user=toto --password=titi db_test > /dev/null"
    @vm.run "echo 'SELECT 1;' | /tmp/wrapper.sh > /dev/null"

    # dbmgr test
    @vm.run "echo 'DROP TABLE toto;' | /tmp/wrapper.sh > /dev/null"
    @vm.run "echo 'DROP TABLE playedsqlscripts;' | /tmp/wrapper.sh > /dev/null"
    @vm.run "mkdir -p /tmp/toto && echo 'CREATE TABLE toto (c int);' > /tmp/toto/00-create.sql && echo 'INSERT INTO toto (c) VALUES (42);' > /tmp/toto/01-insert.sql"
    @vm.run "/tmp/dbmgr.sh --cmd /tmp/wrapper.sh --version toto --dir /tmp/toto > /tmp/log"
    @vm.run "cat /tmp/log | grep -v 'to run' | grep '^+'"
    @vm.run "/tmp/dbmgr.sh --cmd /tmp/wrapper.sh --version toto --dir /tmp/toto > /tmp/log"
    @vm.run_fail "cat /tmp/log | grep -v 'to run' | grep '^+'"
    @vm.run "echo 'SELECT c FROM toto;' | /tmp/wrapper.sh | grep 42"

    # check tomcat deployment
    wait "tomcat deployment", 60, 5 do
        @http.get 8080, "/toto"
        @http.assert_last_response_code 404
        assert_match /Coyote/, @http.response["Server"]
    end

    # check apache basic auth
    @http.get 80, "/"
    @http.assert_last_response_code 401
    assert_equal @http.response['WWW-Authenticate'], "Basic realm=\"apache2 realm\""

    @http.get 80, "/", 'u1', 'u1pass'
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /It works!/

    # Check remove apache2 configuration file
    apache2_conf_file = @vm.capture("ls /etc/apache2/conf.d").split("\n")
    @vm.run "sudo touch /etc/apache2/conf.d/toDelete"
    @vm.run_chef
    new_apache2_conf_file = @vm.capture("ls /etc/apache2/conf.d").split("\n")
    assert_equal apache2_conf_file, new_apache2_conf_file

    # check php deployment
    @http.get 80, "/phpinfo.php", 'u1', 'u1pass'
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /PHP Version/
    @http.assert_last_response_body_regex /abcd123/
    @http.assert_last_response_body_regex /mysql/

    # check pear
    @vm.run "pear list-files Cache_Lite"
    @vm.run "drush version"

    # deploy and chef rails app
    exec_local "cd #{File.join(File.dirname(__FILE__), "..", "conf4")} && TARGET=#{@vm.ip} cap deploy"

    @http.get 81, "/toto"
    @http.assert_last_response_code 404
    @http.assert_last_response_body_regex /This is a 404 page./

    @http.get 81, "/show"
    @http.assert_last_response_code 200
    assert @http.response.body =~ /counter : (\d+)/

    counter = $1.to_i + 1

    @http.get 81, "/show"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /counter : #{counter}/

    # check static files are served by nginx, without unicorn
    @http.get 81, "/my_file.txt"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /static content/

    #apc test
    curl_http_code = @vm.capture "curl -sL -w \"%{http_code}\" \"http://localhost:2323/apc.php\" -o /dev/null"
    assert curl_http_code == "200"

    #mongodb
    @vm.run("sudo netstat -nltp | grep 27017 | grep LISTEN")
    mongo = @vm.capture("mongo --eval 'printjson(db.stats())' | grep db")
    assert_match /\"db\" : \"test\"/, mongo
  end

end
