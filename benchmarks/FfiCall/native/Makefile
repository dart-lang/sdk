# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(37531): Remove this makefile and build with sdk instead when
# benchmark runner gets support for that.

CC=gcc
CCARM=arm-linux-gnueabihf-gcc
CCARM64=aarch64-linux-gnu-gcc
CFLAGS=-Wall -g -O -fPIC

.PHONY: all clean

all: out/linux/x64/libnative_functions.so out/linux/ia32/libnative_functions.so out/linux/arm64/libnative_functions.so out/linux/arm/libnative_functions.so

cipd:
	cipd create -name dart/benchmarks/fficall -in out -install-mode copy

clean:
	rm -rf *.o *.so out

out/linux/x64:
	mkdir -p out/linux/x64

out/linux/x64/native_functions.o: native_functions.c | out/linux/x64
	$(CC) $(CFLAGS) -c -o $@ native_functions.c

out/linux/x64/libnative_functions.so: out/linux/x64/native_functions.o
	$(CC) $(CFLAGS) -s -shared -o $@ out/linux/x64/native_functions.o

out/linux/ia32:
	mkdir -p out/linux/ia32

out/linux/ia32/native_functions.o: native_functions.c | out/linux/ia32
	$(CC) $(CFLAGS) -m32 -c -o $@ native_functions.c

out/linux/ia32/libnative_functions.so: out/linux/ia32/native_functions.o
	$(CC) $(CFLAGS) -m32 -s -shared -o $@ out/linux/ia32/native_functions.o

out/linux/arm64:
	mkdir -p out/linux/arm64

out/linux/arm64/native_functions.o: native_functions.c | out/linux/arm64
	$(CCARM64) $(CFLAGS) -c -o $@ native_functions.c

out/linux/arm64/libnative_functions.so: out/linux/arm64/native_functions.o
	$(CCARM64) $(CFLAGS) -s -shared -o $@ out/linux/arm64/native_functions.o

out/linux/arm:
	mkdir -p out/linux/arm

out/linux/arm/native_functions.o: native_functions.c | out/linux/arm
	$(CCARM) $(CFLAGS) -c -o $@ native_functions.c

out/linux/arm/libnative_functions.so: out/linux/arm/native_functions.o
	$(CCARM) $(CFLAGS) -s -shared -o $@ out/linux/arm/native_functions.o
