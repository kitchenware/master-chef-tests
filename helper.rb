
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
    setup_ssh
    @vm = VM_DRIVER_CLAZZ.new
    @vm.ssh_opts = @ssh_opts
    @vm.init
    wait_ssh
    puts "Virtual machine ready !"
    install_chef
    @http = ::HttpTester.new @vm
  end

  def setup_ssh
    tmp_known_hosts = Tempfile.new('_ssh_known_hosts' + Process.pid.to_s)
    tmp_known_hosts.close
    @tmp_known_hosts = tmp_known_hosts.path
    ssh_config_file = Tempfile.new('_ssh_config_' + Process.pid.to_s)
    user_ssh_config_file = File.join(ENV['HOME'], '.ssh', 'config')
    ssh_config_file.write(File.read(user_ssh_config_file)) if File.exists? user_ssh_config_file
    [
      "ConnectTimeout 5",
      "BatchMode yes",
      "StrictHostKeyChecking no",
      "CheckHostIP no",
      "VerifyHostKeyDNS no",
      "UserKnownHostsFile #{@tmp_known_hosts}",
    ].each do |x|
      ssh_config_file.puts x
    end
    ssh_config_file.close

    ssh_config_file = ssh_config_file.path
    ssh_key = File.join(File.dirname(__FILE__), "ssh", "id_rsa")
    @ssh_opts = "-F #{ssh_config_file} -i #{ssh_key}"

    %x{chmod 0600 #{ssh_key}}
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
      install_user = get_env "USER_FOR_INSTALL"
      prefix = ""
      prefix += "PROXY=#{ENV["PROXY"]} " if ENV["PROXY"]
      prefix += "MASTER_CHEF_URL=#{ENV["MASTER_CHEF_URL"]} " if ENV["MASTER_CHEF_URL"]
      prefix += "MASTER_CHEF_HASH_CODE=#{ENV["MASTER_CHEF_HASH_CODE"]} " if ENV["MASTER_CHEF_HASH_CODE"]
      source_file = File.join(File.dirname(__FILE__), '..', 'runtime', 'bootstrap.sh')
      exec_local "cat #{source_file} | ssh #{@ssh_opts} #{install_user}@#{@vm.ip} \"#{prefix} bash\""
      puts "Chef installed"
    end
  end

  def teardown
    @vm.destroy if @vm && !ENV['DO_NOT_DESTROY_VM']
    File.unlink @tmp_known_hosts if @tmp_known_hosts && File.exist?(@tmp_known_hosts)
  end

end