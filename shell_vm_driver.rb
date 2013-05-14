
class ShellVmDriver < VmDriver

  def initialize
    @clone = get_env("CLONE_SCRIPT")
    @delete = get_env("DELETE_SCRIPT")
    @vm_name = get_env("VM_NAME")
  end

  def init
    @name = "#{@vm_name}".gsub(/#UID#/, Time.now.to_i.to_s)
    puts "Creating vm #{@name}"
    cmd = @clone.gsub(/#NAME#/, @name)
    result = %x{#{cmd}}
    code = $?.exitstatus
    puts result
    raise "Command failed" unless code == 0
    parsed = result.match(/^IP (.*)$/)
    raise "Unable to parse command result" if !parsed
    @ip = parsed[1]
    puts "Vm ready #{@name} : #{ip}"
  end

  def ip
    @ip
  end

  def destroy
    unless ENV["KEEP_SERVER"]
      cmd = @delete.gsub(/#NAME#/, @name)
      exec_local cmd
    end
  end

end

