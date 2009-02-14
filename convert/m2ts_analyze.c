#include <unistd.h>
#include <stdio.h>
#include <arpa/inet.h>

#define ADAPT_FLAG(x) (x[7] & 0x20)
#define ADAPT_LEN_OK(x) (x[8] >= 7)
#define PCR_FLAG(x) (x[9] & 0x10)

int main() {
	uint64_t pcr;
	unsigned int num = 0;
	unsigned char buffer[192];

	while (read(0, buffer, 192) == 192) {
		++num;
		if (ADAPT_FLAG(buffer) && ADAPT_LEN_OK(buffer) && PCR_FLAG(buffer)) {
			pcr = (buffer[10] << 25) | (buffer[11] << 17) | (buffer[12] << 9) |
				(buffer[13] << 1) | (buffer[14] >> 7);
			pcr *= 300;
			pcr += ((buffer[14] & 1) << 8) | buffer[15];

			printf("%d %d %lld (%lld)\n", num, ntohl(*(uint32_t*)buffer) & 0x3fffffff, pcr, pcr & 0x3fffffff);
		} else {
			printf("%d %d\n", num, ntohl(*(uint32_t*)buffer) & 0x3fffffff);
		}
	}

	return 0;
}
