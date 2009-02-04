class IndexWriter
	include Binary
	def initialize stream
		@s = stream
	end

	def write
		header
		info
		indices
	end

	def header
		bin 'INDX0100'

		# Pointers to indices and extensions
		@ind_ptr = ptr 4
		@ext_ptr = ptr 4

		# reserved
		zero 24
	end

	def info
		# No idea what should be here. There is probably 32 bits for field length
		# in the beginning and then some description of the whole disc.
		# We make an educated guess, that just 34+4 bytes of zero would do, and it
		# seems to work in PS3 :P
		len(4) do
			zero 34
		end
	end

	def title idref
		# reserved 1 bit, '1', reserved 31 bits, '1' and reserved 14 bits.
		u8 0x40
		zero 3
		u8 0x40
		zero 1
			
		# "MobjIDRef"
		u16 idref

		# reserved
		zero 4
	end

	def indices
		# titles, in our case
		#  2 : first playback
		#  1 : menu
		#  0 : movie
		
		# first playback title
		len(4) do
			# first playback title
			title 2

			# menu title
			title 1

			# number of movie titles
			u16 1

			1.times do |t|
				# reserved 1 bit, '1', reserved 46 bits
				u8 0x40
				zero 5

				# MovieTitleMobjIDRef
				u16 0

				# reserved
				zero 4
			end
		end
	end
end
