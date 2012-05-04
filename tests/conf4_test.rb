require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestRedmine < Test::Unit::TestCase

  include VmTestHelper

  def test_conf3
    @vm.upload_json "conf4.json"
    @vm.run_chef
    @http.get 8080, "/toto"
    @http.assert_last_response_code 404
    assert_match /Coyote/, @http.response["Server"]
    @vm.run "\"echo 'SELECT 1;' | mysql --user=toto --password=titi test\" > /dev/null"
    @http.get 80, "/"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /It works!/
    @http.get 80, "/phpinfo.php"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /PHP Version/
    @http.assert_last_response_body_regex /abcd123/
    @http.assert_last_response_body_regex /mysql/
  end

end