
def exec_local cmd
  begin
    raise "#{cmd} failed. Aborting..." unless system cmd
  rescue
    raise "#{cmd} failed. Aborting..."
  end
end

def capture_local cmd
  begin
    result = %x{#{cmd}}
    abort "#{cmd} failed. Aborting..." unless $? == 0
    result
  rescue
    abort "#{cmd} failed. Aborting..."
  end
end

def get_env name
  abort "Please specify #{name} variable" unless ENV[name]
  ENV[name]
end
