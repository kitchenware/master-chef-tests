
require File.join(File.dirname(__FILE__), 'ec2_vm_driver.rb')

class Ec2ProxyVmDriver < Ec2VmDriver

  def init
    super
    upload_file File.join(File.dirname(__FILE__), 'proxy_only.sh'), "."
    run "chmod +x proxy_only.sh && sudo ./proxy_only.sh #{ENV['PROXY_IP']} 3128"
    puts "Testing proxy is working"
    run "! curl -s -f http://www.google.com"
    run "http_proxy=http://#{ENV['PROXY_IP']}:3128 curl -s -f http://www.google.com"
    puts "Proxy ready"
  end

end