require File.join(File.dirname(__FILE__), '..', 'helper.rb')
require 'socket'

class TestConf7 < Test::Unit::TestCase

  include VmTestHelper
  include WaitHelper

  def test_conf7
    @vm.upload_json "conf7.json"
    @vm.run_chef
  end

end