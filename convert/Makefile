CFLAGS = -Wall -Wextra -O2
CC = gcc
LDFLAGS = -pthread

BINS := $(patsubst %.c,%,$(wildcard *.c))

all : $(BINS)

%: %.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $?

clean:
	rm -f $(BINS)
