require 'fog'
require 'yaml'

abort "Please specify EC2_CONFIG_FILE variable" unless ENV["EC2_CONFIG_FILE"]

config_file = YAML.load(File.read(ENV["EC2_CONFIG_FILE"]))

fog = Fog::Compute.new config_file[:fog]

vm = fog.servers.find{|x| x.id == config_file[:proxy_vm_id]}

puts "Status of vm : #{config_file[:proxy_vm_id]} : #{vm.state}"

if ARGV[0] == "start" && vm.state == "stopped"
  puts "Starting vm"
  vm.start
  vm.wait_for(120, 5) { ready? }
  puts "VM public ip #{vm.public_ip_address}"
end

if ARGV[0] == "stop" && vm.state == "running"
  puts "Stopping vm"
  vm.stop
end

if ARGV[0] == "ip"
  puts "IP #{vm.public_ip_address}"
end