
SSH_CONFIG_FILE = File.join(File.dirname(__FILE__), "ssh", "config") 
SSH_KEY = File.join(File.dirname(__FILE__), "ssh", "id_rsa")
SSH_OPTS = "-F #{SSH_CONFIG_FILE} -i #{SSH_KEY}"
%x{chmod 0600 #{SSH_KEY}}
%x{rm -f /tmp/tmp_known_hosts}
    
class VmDriver

  def format_chef_ssh cmd
    "ssh #{SSH_OPTS} #{CHEF_USER}@#{ip} #{cmd}"
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
      run "/etc/chef/update.sh"
    end
  end

  def upload_json json
    json_file = File.join(File.dirname(__FILE__), "json", json)
    exec_local "scp #{SSH_OPTS} #{json_file} #{CHEF_USER}@#{ip}:/tmp/local.json"
    self.run "sudo mv /tmp/local.json /etc/chef/local.json"
  end

  def read_chef_local_storage key
    local_storage = YAML.load(capture("sudo cat /var/chef/local_storage.yml"))
    key.split(":").each do |k|
      local_storage = local_storage[k.to_sym]
    end
    local_storage
  end

  def wait_tcp_port tcp_port, timeout = 30, interval = 5
    i = 0
    while i < timeout / interval
      system format_chef_ssh("sudo netstat -nltp | grep #{tcp_port} > /dev/null")
      return if $?.exitstatus == 0
      i += 1
      puts "Wait for TCP port #{tcp_port}"
      sleep interval
    end
    raise "TCP port #{tcp_port} not open after #{timeout} seconds"
  end

end
