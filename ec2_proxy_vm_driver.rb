
require File.join(File.dirname(__FILE__), 'ec2_vm_driver.rb')

class Ec2ProxyVmDriver < Ec2VmDriver

  def init
    super
    exec_local "scp -o StrictHostKeyChecking=no #{File.join(File.dirname(__FILE__), 'proxy_only.sh')} chef@#{@node.public_ip_address}:."
    exec_local "ssh -o StrictHostKeyChecking=no chef@#{@node.public_ip_address} 'chmod +x proxy_only.sh && sudo ./proxy_only.sh #{ENV['PROXY_IP']} 3128'"
  end

end