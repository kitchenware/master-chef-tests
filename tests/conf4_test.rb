require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf4 < Test::Unit::TestCase

  include VmTestHelper

  def test_conf4
    @vm.upload_json "conf4.json"
    @vm.run_chef

    # check tomcat deployment
    @http.get 8080, "/toto"
    @http.assert_last_response_code 404
    assert_match /Coyote/, @http.response["Server"]

    # check mysql config
    @vm.run "\"echo 'SELECT 1;' | mysql --user=toto --password=titi db_test\" > /dev/null"

    # check apache and php deployment
    @http.get 80, "/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /It works!/
    @http.get 80, "/phpinfo.php"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /PHP Version/
    @http.assert_last_response_body_regex /abcd123/
    @http.assert_last_response_body_regex /mysql/

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
  end

end