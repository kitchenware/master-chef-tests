class VboxSnapshotVmDriver < VmDriver

  def initialize
    @name = get_env("NAME")
    @ip = get_env("IP")
    @snapshot = get_env("SNAPSHOT")
    vbox_manage "snapshot \"#{@name}\" restore \"#{@snapshot}\""
    vbox_manage "startvm \"#{@name}\" --type headless"
    sleep 2
  end

  def ip
    @ip
  end

  def destroy
    vbox_manage "controlvm \"#{@name}\" poweroff"
    sleep 2
  end

  private

    def vbox_manage cmd
      exec_local "VBoxManage #{cmd}"
    end

end