
require 'rubygems'
require 'bundler/setup'

require 'test/unit'

require File.join(File.dirname(__FILE__), 'vm_helper.rb')
require File.join(File.dirname(__FILE__), 'http_helper.rb')
require File.join(File.dirname(__FILE__), 'wait_helper.rb')

module VmTestHelper

  @vm = nil

  def setup
    @vm = vm = VM_DRIVER_CLAZZ.new
    @vm.init
    wait_ssh
    puts "Virtual machine ready !"
    @http = ::HttpTester.new @vm
  end

  def wait_ssh
    puts "Check vm availibity by ssh #{@vm.ip}"
    counter = 0
    while true
      raise "Unable to join #{@vm.ip} by ssh" if counter == 30
      counter += 1
      begin
        %x{#{@vm.format_chef_ssh "uname -a"}}
        break if $?.exitstatus == 0
      rescue
      end
      sleep 2
    end
  end

  def teardown
    @vm.destroy if @vm && !ENV['DO_NOT_DESTROY_VM']
  end

end