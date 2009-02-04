# EP = entry point
# PTS EP = Presentation Time Stream Entry Point
# VO 2004/003908, 04003908.pdf, 08006116.1
class ClpiWriter
	include Binary
	def initialize stream, item
		@s = stream
		@item = item
	end

	def write
		header
		clipinfo
		seq
		program
		# cpi
	end

	def header
		bin 'HDMV0200'

		# Pointers to data
		@seq_ptr = ptr 4
		@prog_info_ptr = ptr 4
		@cpi_ptr = ptr 4
		@clip_mark_ptr = ptr 4
		@ext_data_ptr = ptr 4
		
		# reserved, zero
		zero 12
	end

	def clipinfo
		len(4) do
			# reserved, zero
			zero 2

			# u8 item.stream_type
			u8 1 # 1 seems to be the main stream type

			# u8 item.application_type
			u8 1 # 1 is a movie application

			# reserved 31 bits, zero
			zero 3
		
			# is cc5, connect condition 5 (seamless connection)
			u8 0

			# u32 @item.ts_recording_rate
			u32 6000000

			u32 @item.packet_count

			# reserved, zero
			zero 128

			type_info
		
			# some unknown data, but only if is_cc5
		end
	end

	def type_info
		len(2) do
			# validity flags, 0x80 seems to be common (?)
			u8 0x80

			# format_id, maybe always "HDMV"?
			bin 'HDMV'

			# unknown length of unknown data, but 25 bytes of zero seems to work :)
			zero 25
		end
	end

	def seq
		set_ptr @seq_ptr
		len(4) do
			# reserved, zero
			zero 1

			# number of ATC sequences (one?)
			u8 1

			1.times do
				# spn_atc_start, 0?
				u32 0

				# number of STC sequences (one?)
				u8 1

				# Offset STC id (zero?)
				u8 0

				1.times do
					# PCR PID (0x1011 works?)
					u16 0x1011 # TODO: or 0x1001?

					# SPN STC start (0?)
					u32 0

					# presentation start and end
					u32((@item.in_time * 45000).round)
					u32((@item.out_time * 45000).round)
				end
			end
		end
	end

	def program
		set_ptr @prog_info_ptr
		len(4) do
			# reserved, zero
			zero 1

			# number of programs (one?)
			u8 1

			1.times do
				# SPN program sequence start (0?)
				u32 0

				# program map pid (256?)
				u16 256

				# number of streams
				u8 @item.all_streams.size

				# number of groups (0?)
				u8 0

				@item.all_streams.each do |ss|
					# PID
					u16 ss.pid

					stream_attrs ss
				end
			end
		end
	end

	def stream_attrs ss
		len(1) do
			u8 ss.coding_type

			if ss.video?
				# format (4 bits)
				# rate (4 bits)
				u8(ss.format << 4 | ss.rate)
				# aspect (4 bits)
				# oc_flag == 0x2 (zero will do)
				u8(ss.aspect << 4)
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

			# usually the files seems to have a padding here
			padding 0x15
		end
	end

	def cpi
		set_ptr @cpi_ptr
		len(4) do
			# unknown, 0?
			zero 1

			# lower 4 bits is type, 1?
			u8 1

			ep_map_base_pos = @s.pos

			# unknown, 0?
			zero 1

			# number of streams with cpi info
			u8 item.video_streams.size

			list = item.video_streams.map do |ss|
				# PID
				u16 ss.pid

				# Unknown, 0?
				zero 0

				# EP stream type, 6 bits. 1?
				# Number of EP Coarse records, 16 bits
				# Number of EP Fine records, 18 bits
				u8((1 << 2) | (item.ep_coarse.size >> 14))
				u32(((item.ep_coarse.size << 18) | item.ep_fine.size) & 0xFFFFFFFF)

				# ep map addr relative to ep_map_base_pos
				[ss, ptr(4, ep_map_base_pos)]
			end

			list.each do |ss, ep_map_ptr|
				set_ptr ep_map_ptr
				ep_map ss
			end
		end
	end

	# entry point map
	def ep_map ss
		fine_ptr = ptr(4, @s.pos)
		item.ep_coarse.each do |c|
			# ref_ep_fine_id, 18 bits
			# pts_ep, 14 bits
			u32(c[0] << 18 | c[1])

			# spn_ep
			u32 c[2]
		end

		set_ptr fine_ptr
		item.ep_fine.each do |f|
			# is angle change point, 1 bit, 0
			# i_end_position_offset, 3 bits
			# pts_ep, 11 bits
			# spn_ep, 17 bits
			u32((f[0] << 28) | (f[1] << 17) | f[2])
		end
	end
end
