module Binary
	def bin value
		@s.write value
	end

	def u8 value
		@s.write value.chr
	end

	def u16 value
		@s.write [value].pack('n')
	end

	def u32 value
		@s.write [value].pack('N')
	end

	def zero bytes
		@s.write("\0" * bytes)
	end

	def at pos
		@s.seek pos
		ret = yield
		@s.seek 0, IO::SEEK_END
		ret
	end

	def set_ptr ptr
		cur = @s.pos
		at(ptr[:pos]) { unsigned(ptr[:bytes], cur - ptr[:base]) }
	end

	def len bytes
		tmp = @s.pos
		zero bytes
		@current_pos ||= []
		@current_pos << @s.pos

		ret = yield

		@current_pos.pop
		cur = @s.pos
		at(tmp) { unsigned bytes, cur - tmp - bytes }
		ret
	end

	# Adds padding with zero data so that the whole content length will be bytes
	def padding bytes
		zero(bytes - (@s.pos - @current_pos.last))
	end

	def unsigned bytes, data
		raise ArgumentError.new("bytes should be 1, 2 or 4") unless [1, 2, 4].include?(bytes)
		if bytes == 1
			u8 data
		elsif bytes == 2
			u16 data
		else
			u32 data
		end
	end

	def ptr bytes, base = 0
		tmp = {:pos => @s.pos, :bytes => bytes, :base => base}
		zero bytes
		tmp
	end
end
