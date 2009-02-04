class Playitem
	attr_reader :id, :video_streams, :audio_streams, :packet_count, :filename
	attr_accessor :in_time, :out_time
	def self.from_file base, id, time
		tmp = self.new base, id
		tmp.in_time += time
		tmp.out_time += time
		tmp
	end
	def initialize base, id
		@base, @id = base, id
		@filename = "#{@base}/BDMV/STREAM/%05d.MTS" % id
		@filename_clpi = "#{@base}/BDMV/CLIPINF/%05d.CPI" % id
		@packet_count = File.size(@filename) / 192
		sp = StreamParser.new @filename
		@video_streams = sp.video.map {|v| puts v.inspect; VideoStream.new v }
		@audio_streams = sp.audio.map {|a| puts a.inspect; AudioStream.new a }
		if @video_streams.empty?
			raise "No video streams!"
		end
		@in_time = 0
		@out_time = sp.length
	end
	def all_streams
		@video_streams + @audio_streams
	end
	def save
		# Generate .clpi (.CPI) -files
		File.open(@filename_clpi, 'wb') do |f|
			writer = ClpiWriter.new f, self
			writer.write
		end
	end
end
