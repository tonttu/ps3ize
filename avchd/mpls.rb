# All numbers are big endian
# All lengts exclude the length field itself
class MplsWriter
	include Binary
	attr_accessor :parts

	def initialize stream, parts
		@s = stream
		@parts = parts
	end

	def write
		header
		playlist
	end

	def header
		bin 'MPLS0200'

		@list_pos_ptr = ptr 4
		@mark_pos_ptr = ptr 4
		@ext_pos_ptr = ptr 4
		
		# reserved (zero)
		zero 20

		# blkAppInfoPlayList() ->

		# unknown, 0x0000000E
		u32 0xe

		# play_type
		#   0x0001 == sequential
		#   0x0002 == random
		#   0x0003 == shuffle
		u16 1

		# playback count (random/shuffle)
		u16 0

		# UO-restriction things, we don't want any => zero
		zero 8

		# flags (2 bytes)
		#   0x4000 == audio mix
		#   0x2000 == bypass mixer
		#   0x8000 == random access
		u16 0x4000
	end

	def playlist
		set_ptr @list_pos_ptr
		len(4) do
			# reserved, zero
			u16 0

			# number of play items
			u16 @parts.size

			# number of sub paths
			u16 0

			@parts.each { |p| playitem p }
		end
	end

	def playitem item
		len(2) do
			# clip id filename, chars
			bin("%05d" % item.id)

			# Clip codec identifier
			bin "M2TS"

			# reserved, zero (11 bits)
			# is multi angle (1 bit)
			# connection_condition (4 bits)
			#   0x01
			#   0x05 == seamless connection, but this clip has longer audio
			#   0x06 == second seamless connection
			u16 6

			# STC id (something about System Time Clock discontinuous point)
			u8 0

			# in_time
			u32((item.in_time * 45000).round)

			# out_time
			u32((item.out_time * 45000).round)

			# UO_mask_table
			zero 8

			# PlayItemRandomAccessFlag (1 bit), reserved (7 bit)
			u8 0x80

			# stillmode
			u8 0

			# stilltime or reserved
			u16 0

			# <multiangle_stuff if multi angle is used>

			stn item
		end
	end

	def stn item
		len(2) do
			# reserved, zero
			zero 2

			# number of video streams
			u8 item.video_streams.size

			# number of audio streams
			u8 item.audio_streams.size

			# number of presentation graphic streams
			u8 0

			# number of interactive streams
			u8 0

			# number of secondary audio streams
			u8 0

			# number of secondary video streams
			u8 0

			# number of pip_pg (?, zero)
			u8 0

			# reserved, zero
			zero 5

			item.video_streams.each {|s| stream s}
			item.audio_streams.each {|s| stream s}
		end
	end

	def stream ss
		stream_header ss
		stream_data ss
	end

	def stream_header ss
		len(1) do
			# stream_type (byte) [1, 2, 3 or 4]
			u8 1

			# stream_type in 2, 3, 4: 
			#   subpath_id (byte)
			# stream_type in 2, 4:
			#   subclip_id (byte)

			# pid
			u16 ss.pid

			# unknown, zero
			padding 9
		end
	end

	def stream_data ss
		len(1) do
			# coding_type
			u8 ss.coding_type

			if ss.video?
				# format (4 bits)
				# rate (4 bits)
				u8(ss.format << 4 | ss.rate)
			elsif ss.audio?
				# format (4 bits)
				# rate (4 bits)
				u8(ss.format << 4 | ss.rate)
				# lang, ascii (3 chars)
				bin("%3s" % (ss.lang || 'und'))
			elsif ss.graph?
				# lang, ascii (3 chars)
				bin("%3s" % (ss.lang || 'und'))
			elsif ss.subtitle?
				# char_code
				u8 ss.char_code
				# lang, ascii (3 chars)
				bin("%3s" % (ss.lang || 'und'))
			else
				raise ArgumentError.new("Unknown coding_type #{css.coding_type}")
			end

			# There seems to be some padding / unknown data
			padding 5
		end
	end
end
