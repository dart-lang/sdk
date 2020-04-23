// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'ffi_test_helpers.dart';

// void* mmap(void* addr, size_t length,
//            int prot, int flags,
//            int fd, off_t offset)
typedef MMapNative = Pointer<Uint8> Function(Pointer<Uint8> address, IntPtr len,
    IntPtr prot, IntPtr flags, IntPtr fd, IntPtr offset);
typedef MMap = Pointer<Uint8> Function(
    Pointer<Uint8> address, int len, int prot, int flags, int fd, int offset);
final mmap = processSymbols.lookupFunction<MMapNative, MMap>('mmap');

// int munmap(void *addr, size_t length)
typedef MUnMapNative = IntPtr Function(Pointer<Uint8> address, IntPtr len);
typedef MUnMap = int Function(Pointer<Uint8> address, int len);
final munmap = processSymbols.lookupFunction<MUnMapNative, MUnMap>('munmap');

final processSymbols = DynamicLibrary.process();

const int kProtRead = 1;
const int kProtWrite = 2;

const int kMapPrivate = 2;
const int kMapFixed = 16;
final int kMapAnonymous = Platform.isMacOS ? 0x1000 : 0x20;

const int kMapFailed = -1;

// On 32-bit platforms the upper 4 bytes should be ignored.
const int kIgnoreBytesPositive = 0x1122334400000000;
const int kIgnoreBytesNegative = 0xffddccbb00000000;

void swapBytes(
    Pointer<Uint8> memoryView, int indexOffset, int indexA, int indexB) {
  final int oldA = memoryView[indexOffset + indexA];
  memoryView[indexOffset + indexA] = memoryView[indexOffset + indexB];
  memoryView[indexOffset + indexB] = oldA;
}

void testLoadsAndStores(int indexOffset, Pointer<Uint8> memory) {
  for (int i = 0; i < 10; ++i) {
    memory[indexOffset + i] = 10 + i;
  }
  Expect.listEquals(<int>[10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
      memory.offsetBy(indexOffset).asTypedList(10));

  for (int i = 0; i < 9; ++i) {
    swapBytes(memory, indexOffset + 0, i, i + 1);
  }
  Expect.listEquals(<int>[11, 12, 13, 14, 15, 16, 17, 18, 19, 10],
      memory.offsetBy(indexOffset).asTypedList(10));
  for (int i = 0; i < 9; ++i) {
    swapBytes(memory, indexOffset + kIgnoreBytesPositive, i, i + 1);
  }
  Expect.listEquals(<int>[12, 13, 14, 15, 16, 17, 18, 19, 10, 11],
      memory.offsetBy(indexOffset).asTypedList(10));
  for (int i = 0; i < 9; ++i) {
    swapBytes(memory, indexOffset + kIgnoreBytesNegative, i, i + 1);
  }
  Expect.listEquals(<int>[13, 14, 15, 16, 17, 18, 19, 10, 11, 12],
      memory.offsetBy(indexOffset).asTypedList(10));
}

void testOnHighOrLowMemory(Pointer<Uint8> memory, int indexOffset) {
  testLoadsAndStores(indexOffset, memory);
  testLoadsAndStores(indexOffset, memory.offsetBy(5));
  testLoadsAndStores(indexOffset, memory.offsetBy(-5));
  testLoadsAndStores(indexOffset, memory.offsetBy(kIgnoreBytesPositive + 5));
  testLoadsAndStores(indexOffset, memory.offsetBy(kIgnoreBytesNegative + 5));
  testLoadsAndStores(indexOffset, memory.offsetBy(kIgnoreBytesPositive - 5));
  testLoadsAndStores(indexOffset, memory.offsetBy(kIgnoreBytesNegative - 5));
  final m2 = Pointer<Uint8>.fromAddress(kIgnoreBytesPositive + memory.address);
  Expect.equals(memory, m2); //# 01: ok
  Expect.equals(memory.address, m2.address); //# 01: ok
  testLoadsAndStores(indexOffset, m2);
  final m3 = Pointer<Uint8>.fromAddress(kIgnoreBytesNegative + memory.address);
  Expect.equals(memory, m3); //# 01: ok
  Expect.equals(memory.address, m3.address); //# 01: ok
  testLoadsAndStores(indexOffset, m3);
}

const int kPageSize = 4096;

withMMapedAddress(
    Pointer<Uint8> fixedAddress, void fun(Pointer<Uint8> address)) {
  final result = mmap(fixedAddress, kPageSize, kProtRead | kProtWrite,
      kMapAnonymous | kMapFixed | kMapPrivate, 0, 0);
  if (result.address == kMapFailed) {
    throw 'Could not mmap @0x${fixedAddress.address.toRadixString(16)}!';
  }
  Expect.equals(fixedAddress, result); //# 01: ok
  Expect.equals(fixedAddress.address, result.address); //# 01: ok
  try {
    fun(result);
  } finally {
    if (munmap(result, kPageSize) != 0) {
      throw 'Failed to unmap memory!';
    }
  }
}

main() {
  final bool is32BitProcess = sizeOf<Pointer<Uint8>>() == 4;

  // User space processes usually have
  //   * the lower 3 GB available on Linux/Android on 32bit OS
  //   * full 4 GB available on Linux/Android on 64bit OS
  //   * full 4 GB available on MacOS
  // So we choose high and low addresses that fall into lower 3 GB.
  if (is32BitProcess && !Platform.isWindows) {
    final highMemoryAddress = Pointer<Uint8>.fromAddress(0xaaaa0000);
    final lowMemoryAddress = Pointer<Uint8>.fromAddress(0x11110000);
    withMMapedAddress(lowMemoryAddress, (Pointer<Uint8> lowMemory) {
      withMMapedAddress(highMemoryAddress, (Pointer<Uint8> highMemory) {
        testOnHighOrLowMemory(lowMemory, 2048);
        testOnHighOrLowMemory(highMemory, 2048);
        testOnHighOrLowMemory(
            lowMemory, 2048 + highMemory.address - lowMemory.address);
        testOnHighOrLowMemory(
            highMemory, 2048 + lowMemory.address - highMemory.address);
      });
    });
  }
}
