
class ShellVmDriver < VmDriver

  def initialize
    @clone = get_env("CLONE_SCRIPT")
    @delete = get_env("DELETE_SCRIPT")
  end

  def init
    @name = "master_chef_#{Time.now.to_i}"
    puts "Creating vm #{@name}"
    cmd = @clone.gsub(/#NAME#/, @name)
    result = capture_local cmd
    puts result
    parsed = result.match(/^IP (.*)$/)
    raise "Unable to parse command result" if !parsed
    @ip = parsed[1]
    puts "Vm ready #{@name} : #{@ip}"
  end

  def ip
    @ip
  end

  def destroy
    cmd = @delete.gsub(/#NAME#/, @name)
    exec_local cmd
  end

end

