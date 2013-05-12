
require 'tempfile'

ssh_config_file = Tempfile.new '_ssh_config'
user_ssh_config_file = File.join(ENV['HOME'], '.ssh', 'config')
ssh_config_file.write(File.read(user_ssh_config_file)) if File.exists? user_ssh_config_file
ssh_config_file.write(File.read(File.join(File.dirname(__FILE__), "ssh", "config")))
ssh_config_file.close
SSH_CONFIG_FILE = ssh_config_file.path
SSH_KEY = File.join(File.dirname(__FILE__), "ssh", "id_rsa")
SSH_OPTS = "-F #{SSH_CONFIG_FILE} -i #{SSH_KEY}"
%x{chmod 0600 #{SSH_KEY}}
%x{rm -f /tmp/tmp_known_hosts}

class VmDriver

  def format_chef_ssh cmd
    "ssh #{SSH_OPTS} #{CHEF_USER}@#{ip} \"#{cmd}\""
  end

  def run cmd
    begin
      raise "ssh #{CHEF_USER} : #{cmd} failed. Aborting..." unless system format_chef_ssh(cmd)
    rescue
      raise "ssh #{CHEF_USER} : #{cmd} failed. Aborting..."
    end
  end

  def capture cmd
    result = `#{format_chef_ssh(cmd)}`
    raise "ssh capture #{CHEF_USER} : #{cmd} failed. Aborting..." unless $?.exitstatus == 0
    result
  end

  def run_chef
    if ENV["CHEF_LOCAL"]
      exec_local "../../runtime/chef_local.rb #{ip}"
    else
      chef_cmd = ENV['OMNIBUS'] ? "/opt/master-chef/bin/master-chef.sh" : "/etc/chef/update.sh"
      prefix = ""
      prefix = "http_proxy=http://#{ENV["PROXY_IP"]}:3128 https_proxy=http://#{ENV["PROXY_IP"]}:3128" if ENV["PROXY_IP"]
      prefix = "http_proxy=#{ENV["PROXY"]} https_proxy=#{ENV["PROXY"]}" if ENV["PROXY"]
      run "#{prefix} #{chef_cmd}"
    end
  end

  def upload_file from, to
    exec_local "scp #{SSH_OPTS} #{from} #{CHEF_USER}@#{ip}:#{to}"
  end

  def upload_json json
    upload_file File.join(File.dirname(__FILE__), "json", json), "/tmp/local.json"
    json_path = ENV['OMNIBUS'] ? "/opt/master-chef/etc" : "/etc/chef"
    self.run "sudo mv /tmp/local.json #{json_path}/local.json"
  end

end
