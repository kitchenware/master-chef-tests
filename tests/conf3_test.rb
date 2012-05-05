require File.join(File.dirname(__FILE__), '..', 'helper.rb')

class TestConf3 < Test::Unit::TestCase

  include VmTestHelper

  def test_conf3
    @vm.upload_json "conf3.json"
    @vm.run_chef
    @http.get 80, "/redmine"
    @http.assert_last_response_code 200
    @http.assert_last_response_body_regex /Redmine/
    date = @vm.capture("date -u && date").split("\n").map{|x| x =~ /^.*(\d\d:\d\d:\d\d).*$/; $1}
    assert_not_equal date[0], date[1]
  end

end