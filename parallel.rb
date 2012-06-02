require 'rubygems'
require 'peach'
require 'popen4'

def header pname, console = ""
  prefix = "#{pname}::#{console}".ljust(20)
  "[#{prefix} #{Time.now.to_s}]"
end

result = {}
ARGV.peach do |f|
  file_name = File.basename(f)
  status = POpen4::popen4("ruby -I. #{f}") do |stdout, stderr, stdin, pid|
    while !stdout.eof? || !stderr.eof?
      ra = []
      ra << stdout unless stdout.eof?
      ra << stderr unless stderr.eof?
      r, w, e = IO.select(ra, [], [])
      r.each do |io|
        puts "#{header file_name, "out"} #{stdout.readline}" if io == stdout
        puts "#{header file_name, "err"} #{stderr.readline}" if io == stderr
      end
    end
  end
  result[f] = status
end

ok = true
result.each do |k, v|
  if v.exitstatus != 0
    ok = false
    puts "#{header "master"} Test failed : #{k}"
  end
end
if ok
  puts "#{header "master"} All #{result.size} tests ok"
else
  abort
end