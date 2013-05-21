
require 'rubygems'
require 'bundler/setup'

require 'test/unit'

require File.join(File.dirname(__FILE__), 'misc_helper.rb')
require File.join(File.dirname(__FILE__), 'vm_helper.rb')
require File.join(File.dirname(__FILE__), 'http_helper.rb')
require File.join(File.dirname(__FILE__), 'wait_helper.rb')

SSH_RETRY_DELAY = (ENV["SSH_RETRY_DELAY"] || "2").to_i
SSH_MAX_RETRY = (ENV["SSH_MAX_RETRY"] || "45").to_i
SSH_CONNECT_OK = (ENV["SSH_CONNECT_OK"] || "1").to_i

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
    puts "Check vm availibity by ssh #{@vm.ip} (retry delay #{SSH_RETRY_DELAY}, max #{SSH_MAX_RETRY}, ok #{SSH_CONNECT_OK})"
    ok = 0
    counter = 0
    while ok != SSH_CONNECT_OK
      raise "Unable to join #{@vm.ip} by ssh" if counter == SSH_MAX_RETRY
      sleep 2 unless counter == 0
      counter += 1
      begin
        res = %x{#{@vm.format_chef_ssh "uname -a"} 2>&1}
        code = $?.exitstatus
        puts res
        ok += 1 if code == 0 || res.match(/Permission denied/)
      rescue
      end
    end
  end

  def install_chef
    if ENV["CHEF_INSTALL"]
      cmd = File.join(File.dirname(__FILE__), '..', 'runtime', "install_chef_#{get_env("CHEF_INSTALL")}_x86_64.sh") + " #{@vm.ip}"
      puts "Running chef install command : #{cmd}"
      exec_local "/bin/sh -c 'SSH_OPTS=\"#{SSH_OPTS}\" #{cmd}'"
      puts "Chef installed"
    end
  end

  def teardown
    @vm.destroy if @vm && !ENV['DO_NOT_DESTROY_VM']
  end

end