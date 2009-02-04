#!/usr/bin/env ruby

if ARGV.size != 1
	$stderr.puts "Usage: #{$0} <dir that has BDMV subdir>"
	exit 1
end

Dir["#{ARGV.first}/BDMV/CLIPINF/*CPI"].each do |cpi|
	puts cpi
	real_size = File.size(cpi.sub(%r{CLIPINF/(.*)\.CPI}, 'STREAM/\\1.MTS')) / 192
	File.open(cpi, 'r+b') do |file|
		file.sysseek(0x38)
		current_size = file.sysread(4).unpack('N').first
		if current_size == real_size
			puts(" - Current size 0x%08x is correct, do not fix" % current_size)
			next
		end
		puts(" - Current size: 0x%08x, correct size: 0x%08x, fixing" % [current_size, real_size])
		file.sysseek(0x38)
		file.syswrite([real_size].pack('N'))
		puts " - fixed"
	end
end
