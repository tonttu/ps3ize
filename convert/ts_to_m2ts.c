#include <unistd.h>
#include <stdio.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdlib.h>

#define ADAPT_FLAG(x) (x[7] & 0x20)
#define ADAPT_LEN_OK(x) (x[8] >= 7)
#define PCR_FLAG(x) (x[9] & 0x10)

struct meta {
	int num;
	uint64_t diff, pcr;
};

#define BACKLOG_SIZE 64
#define PACKETS_PER_BUFFER 2000

static unsigned char *data[BACKLOG_SIZE];
static struct meta meta[BACKLOG_SIZE];

sem_t pcr_sem, data_sem;
int done = 0;

static void* writer() {
	int num, i;
	unsigned int total = 0;
	double pcr, diff;
	unsigned char *buffer;
	int backlog = 0;
	int semvalue;

	sem_wait(&pcr_sem);
	for (;;) {
		if (done && (done + 1) % BACKLOG_SIZE == backlog &&
				sem_getvalue(&pcr_sem, &semvalue) == 0 && semvalue == 0)
			break;
		else
			sem_wait(&pcr_sem);

		pcr = (double)meta[backlog].pcr;
		num = meta[backlog].num;
		diff = (double)meta[backlog].diff / (double)num;
		buffer = data[backlog];

		for (i = 0 ; i < num; ++i, buffer += 192) {
			pcr += diff;
			*(uint32_t*)buffer = htonl(((uint32_t)pcr) & 0x3fffffff);
			if (write(1, buffer, 192) != 192) {
				perror("write");
				exit(1);
			}
		}
		total += num;
		fprintf(stderr, "\r%.1f MB", total*192.0f/1024.0f/1024.0f);

		sem_post(&data_sem);
		backlog = (backlog + 1) % BACKLOG_SIZE;
	}
	fprintf(stderr, "\n");
	return NULL;
}

void reader() {
	int num = 0;
	int backlog = 0;
	uint64_t pcr, oldpcr = 0;
	unsigned char *buffer = data[backlog];

	while (read(0, buffer+4, 188) == 188) {
		++num;
		if (ADAPT_FLAG(buffer) && ADAPT_LEN_OK(buffer) && PCR_FLAG(buffer)) {
			pcr = (buffer[10] << 25) | (buffer[11] << 17) | (buffer[12] << 9) |
				(buffer[13] << 1) | (buffer[14] >> 7);
			pcr *= 300;
			pcr += ((buffer[14] & 1) << 8) | buffer[15];

			meta[backlog].num = num;
			if (oldpcr == 0) {
				meta[backlog].diff = 0;
				meta[backlog].pcr = pcr;
			} else {
				meta[backlog].diff = pcr - oldpcr;
				meta[backlog].pcr = oldpcr;
			}
			sem_post(&pcr_sem);

			oldpcr = pcr;
			backlog = (backlog + 1) % BACKLOG_SIZE;
			num = 0;
		
			sem_wait(&data_sem);
			buffer = data[backlog];
		} else {
			buffer += 192;
		}
		if (num >= PACKETS_PER_BUFFER) {
			fprintf(stderr, "Buffer :(");
			exit(1);
		}
	}
	if (num > 0) {
		meta[backlog].num = num;
		meta[backlog].diff = meta[(backlog == 0 ? BACKLOG_SIZE : backlog) - 1].diff;
		meta[backlog].pcr = oldpcr;
		done = backlog;
		sem_post(&pcr_sem);
		sem_post(&pcr_sem);
	}
}

int main() {
	int i;
	pthread_t thread;

	for (i = 0; i < BACKLOG_SIZE; ++i) {
		if (!(data[i] = malloc(PACKETS_PER_BUFFER*192))) {
			perror("malloc");
			return -1;
		}
	}

	if (sem_init(&pcr_sem, 0, 0)) {
		perror("sem_init 1");
		return -2;
	}

	if (sem_init(&data_sem, 0, BACKLOG_SIZE - 1)) {
		perror("sem_init 2");
		return -3;
	}

	if (pthread_create(&thread, NULL, writer, NULL) != 0)
		return -4;

	reader();

	if (pthread_join(thread, NULL) != 0) 
		return -5;

	sem_destroy(&pcr_sem);
	sem_destroy(&data_sem);

	return 0;
}
