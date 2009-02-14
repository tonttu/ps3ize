/**
 * M2TS files used in AVCHD dirs / Blu-ray dics seems to be ordinary MPEG-TS
 * files with extra 4 byte header in the beginning of every packet.
 *
 * The extra header presumably has copy protection field (2 bits, 00 meaning
 * no protection) and timestamp that has the lower 30 bits of MPEG-TS PCR
 * field (normally 33+9 bits). The field is in big endian format.
 *
 * This small program only strips the extra header.
 * 
 * Usage: m2ts_to_ts <00001.m2ts >output.ts
 */

#include <unistd.h>
#include <stdio.h>

int main() {
	char buffer[192];
	unsigned int count = 0;
	while (read(0, buffer, 192) == 192) {
		write(1, buffer+4, 188);
		if (!(count & 0xFFF))
			fprintf(stderr, "\r%.0f MB", count*188.0f/1024.0f/1024.0f);
		++count;
	}
	fprintf(stderr, "\r%.1f MB, %u packets\n", count*188.0f/1024.0f/1024.0f, count);
	return 0;
}
