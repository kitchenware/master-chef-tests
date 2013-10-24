
require 'tempfile'

class VmDriver

  attr_accessor :ssh_opts

  def format_chef_ssh cmd
    "ssh #{@ssh_opts} #{CHEF_USER}@#{ip} \"#{cmd}\""
  end

  def run cmd
    begin
      raise "ssh #{CHEF_USER} : #{cmd} failed. Aborting..." unless system format_chef_ssh(cmd)
    rescue
      raise "ssh #{CHEF_USER} : #{cmd} failed. Aborting..."
    end
  end

  def run_fail cmd
    begin
      system format_chef_ssh(cmd)
      raise "ssh #{CHEF_USER} : #{cmd} should fail. Aborting..."
    rescue
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
      chef_cmd = "/opt/master-chef/bin/master-chef.sh"
      prefix = ""
      prefix = "http_proxy=http://#{ENV["PROXY_IP"]}:3128 https_proxy=http://#{ENV["PROXY_IP"]}:3128" if ENV["PROXY_IP"]
      prefix = "http_proxy=#{ENV["PROXY"]} https_proxy=#{ENV["PROXY"]}" if ENV["PROXY"]
      run "#{prefix} #{chef_cmd}"
    end
    check_last_chef_run
  end

  def check_last_chef_run
    last_chef_run = "/opt/master-chef/var/last/log"
    log = capture "sudo cat #{last_chef_run}"
    raise "Not a chef log" unless log.match /INFO: \*\*\* Chef (.*) \*\*\*/
    [
      /WARN:/,
      /Overriding duplicate/
    ].each do |x|
      raise "Error : pattern #{x} found in log" if log.match(x)
    end
  end

  def upload_file from, to
    exec_local "scp #{@ssh_opts} #{from} #{CHEF_USER}@#{ip}:#{to}"
  end

  def upload_json json
    upload_file File.join(File.dirname(__FILE__), "json", json), "/tmp/local.json"
    json_path = "/opt/master-chef/etc"
    self.run "sudo mv /tmp/local.json #{json_path}/local.json"
  end

end
