
require 'rubygems'
require 'bundler/setup'

require 'test/unit'

require File.join(File.dirname(__FILE__), 'misc_helper.rb')
require File.join(File.dirname(__FILE__), 'vm_helper.rb')
require File.join(File.dirname(__FILE__), 'http_helper.rb')
require File.join(File.dirname(__FILE__), 'wait_helper.rb')

module VmTestHelper

  @vm = nil

  def setup
    @vm = VM_DRIVER_CLAZZ.new
    @vm.init
    wait_ssh
    puts "Virtual machine ready !"
    install_chef
    @http = ::HttpTester.new @vm
  end

  def wait_ssh
    puts "Check vm availibity by ssh #{@vm.ip}"
    counter = 0
    while true
      raise "Unable to join #{@vm.ip} by ssh" if counter == 30
      counter += 1
      begin
        res = %x{#{@vm.format_chef_ssh "uname -a"} 2>&1}
        code = $?.exitstatus
        puts res
        break if code == 0 || res.match(/Permission denied/)
      rescue
      end
      sleep 2
    end
  end

  def install_chef
    if ENV["CHEF_INSTALL"]
      cmd = File.join(File.dirname(__FILE__), '..', 'runtime', "install_chef_#{get_env("DISTRO")}_x86_64.sh") + " #{@vm.ip}"
      puts "Running chef install command : #{cmd}"
      exec_local "/bin/sh -c 'SSH_OPTS=\"#{SSH_OPTS}\" #{cmd}'"
      cmd = File.join(File.dirname(__FILE__), '..', 'runtime', "bootstrap_chef_solo#{ENV["OMNIBUS"] ? "_omnibus" : ""}_script.sh") + " #{@vm.ip}"
      puts "Running master chef bootstrap command : #{cmd}"
      exec_local "/bin/sh -c 'SSH_OPTS=\"#{SSH_OPTS}\" #{cmd}'"
      puts "Chef installed"
    end
  end

  def teardown
    @vm.destroy if @vm && !ENV['DO_NOT_DESTROY_VM']
  end

end