# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(nweiz): replace this with a .gypi file

CC = gcc
CFLAGS = -fPIC -m32 -I ../../runtime/include/ -g
LDFLAGS = -shared -m32 -g -larchive -Wl,-soname,libdart_archive.so

all: libdart_archive.so

libdart_archive.so: dart_archive.o entry.o messaging.o reader.o
	$(CC) $(LDFLAGS) -o $@ dart_archive.o entry.o messaging.o reader.o

dart_archive.o: dart_archive.c dart_archive.h
	$(CC) $(CFLAGS) -c $<

entry.o: entry.c entry.h messaging.h dart_archive.h
	$(CC) $(CFLAGS) -c $<

messaging.o: messaging.c messaging.h dart_archive.h
	$(CC) $(CFLAGS) -c $<

reader.o: reader.c reader.h entry.h messaging.h dart_archive.h
	$(CC) $(CFLAGS) -c $<
