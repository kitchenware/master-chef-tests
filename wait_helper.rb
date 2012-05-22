
module WaitHelper

  def wait message, timeout = 30, interval = 5
    i = 0
    while i < timeout / interval
      begin
        yield
        return
      rescue
        puts message
        sleep interval
      end
    end
    raise "Timeout #{message}"
  end

end