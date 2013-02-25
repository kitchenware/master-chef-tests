
require File.join(File.dirname(__FILE__), 'ec2_vm_driver.rb')

class Ec2ProxyVmDriver < Ec2VmDriver

  def init
    super
    upload_file File.join(File.dirname(__FILE__), 'proxy_only.sh'), "."
    run "chmod +x proxy_only.sh && sudo ./proxy_only.sh #{ENV['PROXY_IP']} 3128"
  end

end