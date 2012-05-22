
module WaitHelper

  def wait message, timeout = 30, interval = 5
    stop = Time.now.to_i + timeout
    while stop > Time.now.to_i
      begin
        yield
        return
      rescue
        puts message
        sleep interval
      end
    end
    raise "Timeout : #{message}"
  end

end