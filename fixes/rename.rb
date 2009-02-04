#!/usr/bin/env ruby

if ARGV.size != 1
	$stderr.puts "Usage: #{$0} <dir that has BDMV subdir>"
	exit 1
end

def rename base, file
	full = File.join base, file
	if file != file.upcase
		file.upcase!
    # Two phase rename if and when we are using fat
		File.rename full, File.join(base, file + '_')
		full = File.join base, file
		File.rename File.join(base, file + '_'), full
	end

	newfile = file.sub(/\.BDMV$/, '.BDM').sub(/\.CLPI$/, '.CPI').sub(/\.MPLS$/, '.MPL').
		sub(/\.M2TS$/, '.MTS').sub(/^MOVIEOBJECT.BDM$/, 'MOVIEOBJ.BDM')
	if file != newfile
		File.rename full, File.join(base, newfile)
		full = File.join base, newfile
	end

	if File.directory?(full)
		Dir[full + '/*'].each {|f| rename full, File.basename(f)}
	end
end

Dir[ARGV.first + '/*'].each {|f| rename Dir[ARGV.first], File.basename(f)}
