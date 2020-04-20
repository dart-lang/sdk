# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(37531): Remove this makefile and build with sdk instead when
# benchmark runner gets support for that.

REVISION=a86c69888b9a416f5249aacb4690a765be064969

STRIPARM=arm-linux-gnueabihf-strip
STRIPARM64=aarch64-linux-gnu-strip

.PHONY: all cipd build/linux/x64 build/linux/ia32 build/linux/arm build/linux/arm64 clean

all: out/linux/x64/libssl.so out/linux/x64/libcrypto.so out/linux/ia32/libssl.so out/linux/ia32/libcrypto.so out/linux/arm/libssl.so out/linux/arm/libcrypto.so out/linux/arm64/libssl.so out/linux/arm64/libcrypto.so

cipd:
	cipd create -name dart/benchmarks/ffiboringssl -in out -install-mode copy -tag commit:$(REVISION)

src:
	test -e src || git clone https://boringssl.googlesource.com/boringssl src
	cd src && git reset --hard $(REVISION)

build/linux/x64: src
	mkdir -p build/linux/x64 && cd build/linux/x64 && cmake -DBUILD_SHARED_LIBS=1 ../../../src && make

out/linux/x64:
	mkdir -p out/linux/x64

out/linux/x64/libssl.so: build/linux/x64 out/linux/x64
	cp build/linux/x64/ssl/libssl.so $@
	strip $@

out/linux/x64/libcrypto.so: build/linux/x64 out/linux/x64
	cp build/linux/x64/crypto/libcrypto.so $@
	strip $@

build/linux/ia32: src
	mkdir -p build/linux/ia32 && cd build/linux/ia32 && cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_TOOLCHAIN_FILE=../../../src/util/32-bit-toolchain.cmake ../../../src && make

out/linux/ia32:
	mkdir -p out/linux/ia32

out/linux/ia32/libssl.so: build/linux/ia32 out/linux/ia32
	cp build/linux/ia32/ssl/libssl.so $@
	strip $@

out/linux/ia32/libcrypto.so: build/linux/ia32 out/linux/ia32
	cp build/linux/ia32/crypto/libcrypto.so $@
	strip $@

build/linux/arm: src
	mkdir -p build/linux/arm && cd build/linux/arm && cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_TOOLCHAIN_FILE=../../../arm.cmake ../../../src && make

out/linux/arm:
	mkdir -p out/linux/arm

out/linux/arm/libssl.so: build/linux/arm out/linux/arm
	cp build/linux/arm/ssl/libssl.so $@
	$(STRIPARM) $@

out/linux/arm/libcrypto.so: build/linux/arm out/linux/arm
	cp build/linux/arm/crypto/libcrypto.so $@
	$(STRIPARM) $@

build/linux/arm64: src
	mkdir -p build/linux/arm64 && cd build/linux/arm64 && cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_TOOLCHAIN_FILE=../../../arm64.cmake ../../../src && make

out/linux/arm64:
	mkdir -p out/linux/arm64

out/linux/arm64/libssl.so: build/linux/arm64 out/linux/arm64
	cp build/linux/arm64/ssl/libssl.so $@
	$(STRIPARM64) $@

out/linux/arm64/libcrypto.so: build/linux/arm64 out/linux/arm64
	cp build/linux/arm64/crypto/libcrypto.so $@
	$(STRIPARM64) $@

clean:
	rm -rf build src out
