require 'fileutils'
require 'ftools'

require 'binary.rb'
require 'clpi.rb'
require 'mpls.rb'
require 'item.rb'
require 'stream.rb'
require 'index.rb'

def assert test
	raise "Assertion failed" unless test
end

class Video
	def initialize base
		@base = base
		@items = []
		@pos = 0
	end
	def create_item id
		item = Playitem.from_file @base, id, @pos
		@items << item
		@pos = item.out_time
		item
	end
	def save
		@items.each {|i| i.save}
		# Generate .mpls
		File.open("#{@base}/BDMV/PLAYLIST/%05d.MPL" % 0, 'wb') do |f|
			writer = MplsWriter.new f, @items
			writer.write
		end
	end
end

class Avchd
	def self.skel b
		for i in %w[BACKUP/BDJO BACKUP/CLIPINF BACKUP/PLAYLIST AUXDATA BDJO STREAM CLIPINF META	PLAYLIST]
			FileUtils.mkdir_p "#{b}/BDMV/#{i}"
		end
		FileUtils.mkdir_p "#{b}/CERTIFICATE/BACKUP"
	end
	def initialize b
		@base = "#{b}/AVCHD"
		Avchd.skel @base
		@videos = []
	end
	def create_video
		v = Video.new @base
		@videos << v
		v
	end
	def save
		@videos.each {|v| v.save}
		File.open("#{@base}/BDMV/INDEX.BDM", 'wb') do |f|
			writer = IndexWriter.new f
			writer.write
		end
#		File.open("#{@base}/BDMV/MOVIEOBJ.BDM", 'wb') do |f|
#			writer = MovieObjWriter.new f
#			writer.write
#		end

		File.cp "#{@base}/BDMV/INDEX.BDM", "#{@base}/BDMV/BACKUP/INDEX.BDM"
		#File.cp "#{@base}/BDMV/MOVIEOBJ.BDM", "#{@base}/BDMV/BACKUP/MOVIEOBJ.BDM"
		Dir["#{@base}/BDMV/CLIPINF/*CPI"].each do |f|
			File.cp f, "#{@base}/BDMV/BACKUP/CLIPINF/#{File.basename f}"
		end
		Dir["#{@base}/BDMV/PLAYLIST/*MPL"].each do |f|
			File.cp f, "#{@base}/BDMV/BACKUP/PLAYLIST/#{File.basename f}"
		end
	end
end

