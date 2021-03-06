
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
    @ssh_known_hosts = "/tmp/_ssh_known_hosts_" + Process.pid.to_s
    @ssh_config_file = "/tmp/_ssh_config_" + Process.pid.to_s
    ssh_config_file = File.open(@ssh_config_file, 'w')

    user_ssh_config_file = File.join(ENV['HOME'], '.ssh', 'config')
    ssh_config_file.write(File.read(user_ssh_config_file)) if File.exists? user_ssh_config_file

    [
      "Host *",
      "",
      "ConnectTimeout 5",
      "BatchMode yes",
      "StrictHostKeyChecking no",
      "CheckHostIP no",
      "VerifyHostKeyDNS no",
      "UserKnownHostsFile #{@ssh_known_hosts}",
      "",
    ].each do |x|
      ssh_config_file.puts x
    end
    ssh_config_file.close

    ssh_key = File.join(File.dirname(__FILE__), "ssh", "id_rsa")
    @ssh_opts = "-F #{@ssh_config_file} -i #{ssh_key}"

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
      prefix += "APT_PROXY=#{ENV["APT_PROXY"]} " if ENV["APT_PROXY"]
      prefix += "PROXY=#{ENV["PROXY"]} " if ENV["PROXY"]
      prefix += "MASTER_CHEF_URL=#{ENV["MASTER_CHEF_URL"]} " if ENV["MASTER_CHEF_URL"]
      prefix += "MASTER_CHEF_HASH_CODE=#{ENV["MASTER_CHEF_HASH_CODE"]} " if ENV["MASTER_CHEF_HASH_CODE"]
      prefix += "MASTER_CHEF_DIRECT_ACCESS_URL=#{ENV["MASTER_CHEF_DIRECT_ACCESS_URL"]} " if ENV["MASTER_CHEF_DIRECT_ACCESS_URL"]
      if ENV["CHEF_LOCAL"]
        source_file = "cat #{File.join(File.dirname(__FILE__), '..', 'master-chef', 'runtime', 'bootstrap.sh')}"
      else
        source_file = "curl -s https://raw.github.com/kitchenware/master-chef/master/runtime/bootstrap.sh -o /tmp/bootstrap.sh && cat /tmp/bootstrap.sh"
      end
      exec_local "#{source_file} | ssh #{@ssh_opts} #{install_user}@#{@vm.ip} \"#{prefix} bash\""
      puts "Chef installed"
    end
  end

  def teardown
    @vm.destroy if @vm && !ENV['DO_NOT_DESTROY_VM']
    File.unlink @ssh_known_hosts if @ssh_known_hosts && File.exist?(@ssh_known_hosts)
    File.unlink @ssh_config_file if @ssh_config_file && File.exist?(@ssh_config_file)
  end

end