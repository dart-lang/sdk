// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types
// ignore_for_file: deprecated_member_use
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// int open(const char *path, int oflag, ...);
@Native<Int Function(Pointer<Utf8>, Int)>(symbol: "open")
external int open(Pointer<Utf8> filename, int flags);

// int close(int fd);
@Native<Int Function(Int)>(symbol: "close")
external int close(int fd);

// void* mmap(void* addr, size_t length,
//            int prot, int flags,
//            int fd, off_t offset)
@Native<Pointer<Uint8> Function(Pointer<Uint8>, Size, Int, Int, Int, IntPtr)>()
external Pointer<Uint8> mmap(
    Pointer<Uint8> address, int len, int prot, int flags, int fd, int offset);

// int munmap(void *addr, size_t length)
@Native<IntPtr Function(Pointer<Uint8> address, Size len)>()
external int munmap(Pointer<Uint8> address, int len);

final DynamicLibrary processSymbols = DynamicLibrary.process();
final munmapNative = processSymbols.lookup<Void>('munmap');
final closeNative = processSymbols.lookup<Void>('close');
final freeNative = processSymbols.lookup<Void>('free');

// int mprotect(void *addr, size_t len, int prot)
@Native<Int Function(Pointer<Uint8>, Size, Int)>(symbol: "mprotect")
external int mprotect(Pointer<Uint8> addr, int len, int prot);

// DART_EXPORT Dart_Handle
// Dart_NewExternalTypedDataWithFinalizer(Dart_TypedData_Type type,
//                                       void* data,
//                                       intptr_t length,
//                                       void* peer,
//                                       intptr_t external_allocation_size,
//                                       Dart_HandleFinalizer callback)
typedef Dart_NewExternalTypedDataWithFinalizerNative = Handle Function(
    Int, Pointer<Void>, IntPtr, Pointer<Void>, IntPtr, Pointer<Void>);
typedef Dart_NewExternalTypedDataWithFinalizerDart = Object Function(
    int, Pointer<Void>, int, Pointer<Void>, int, Pointer<Void>);
final Dart_NewExternalTypedDataWithFinalizer = processSymbols.lookupFunction<
        Dart_NewExternalTypedDataWithFinalizerNative,
        Dart_NewExternalTypedDataWithFinalizerDart>(
    'Dart_NewExternalTypedDataWithFinalizer');

const int kPageSize = 4096;
const int kProtRead = 1;
const int kProtWrite = 2;
const int kProtExec = 4;
const int kMapPrivate = 2;
const int kMapAnon = 0x20;
const int kMapFailed = -1;

//  #include <cstddef>
//  #include <cstdint>
//
//  struct PeerData {
//    int (*close)(int);
//    int (*munmap)(void*, size_t);
//    int (*free)(void*);
//    void* mapping;
//    intptr_t size;
//    intptr_t fd;
//  };
//
//  extern "C" void finalizer(void* callback_data, void* peer) {
//    auto data = static_cast<PeerData*>(peer);
//    data->munmap(data->mapping, data->size);
//    data->close(data->fd);
//    data->free(peer);
//  }
//
//  riscv64-linux-gnu-g++ -O2 -c -o a.o a.cc
//  riscv64-linux-gnu-objcopy -O binary --only-section=.text a.o a.bin
//  xxd -i a.bin
const finalizerCode = <Abi, List<int>>{
  Abi.linuxX64: [
    0x53, 0x48, 0x89, 0xf3, 0x48, 0x8b, 0x76, 0x20, 0x48, 0x8b, 0x7b, 0x18, //
    0xff, 0x53, 0x08, 0x8b, 0x7b, 0x28, 0xff, 0x13, 0x48, 0x8b, 0x43, 0x10, //
    0x48, 0x89, 0xdf, 0x5b, 0xff, 0xe0, //
  ],
  Abi.linuxIA32: [
    0x53, 0x83, 0xec, 0x10, 0x8b, 0x5c, 0x24, 0x1c, 0xff, 0x73, 0x10, 0xff, //
    0x73, 0x0c, 0xff, 0x53, 0x04, 0x58, 0xff, 0x73, 0x14, 0xff, 0x13, 0x89, //
    0x5c, 0x24, 0x20, 0x8b, 0x43, 0x08, 0x83, 0xc4, 0x18, 0x5b, 0xff, 0xe0, //
  ],
  Abi.linuxArm64: [
    0xfd, 0x7b, 0xbe, 0xa9, 0xfd, 0x03, 0x00, 0x91, 0x22, 0x04, 0x40, 0xf9, //
    0xf3, 0x0b, 0x00, 0xf9, 0xf3, 0x03, 0x01, 0xaa, 0x20, 0x84, 0x41, 0xa9, //
    0x40, 0x00, 0x3f, 0xd6, 0x61, 0x02, 0x40, 0xf9, 0x60, 0x2a, 0x40, 0xb9, //
    0x20, 0x00, 0x3f, 0xd6, 0x61, 0x0a, 0x40, 0xf9, 0xe0, 0x03, 0x13, 0xaa, //
    0xf3, 0x0b, 0x40, 0xf9, 0xf0, 0x03, 0x01, 0xaa, 0xfd, 0x7b, 0xc2, 0xa8, //
    0x00, 0x02, 0x1f, 0xd6, //
  ],
  Abi.linuxArm: [
    0x10, 0x40, 0x2d, 0xe9, 0x01, 0x40, 0xa0, 0xe1, 0x10, 0x10, 0x91, 0xe5, //
    0x04, 0x30, 0x94, 0xe5, 0x0c, 0x00, 0x94, 0xe5, 0x33, 0xff, 0x2f, 0xe1, //
    0x00, 0x30, 0x94, 0xe5, 0x14, 0x00, 0x94, 0xe5, 0x33, 0xff, 0x2f, 0xe1, //
    0x08, 0x30, 0x94, 0xe5, 0x04, 0x00, 0xa0, 0xe1, 0x10, 0x40, 0xbd, 0xe8, //
    0x13, 0xff, 0x2f, 0xe1, //
  ],
  Abi.linuxRiscv64: [
    0x41, 0x11, 0x22, 0xe0, 0x2e, 0x84, 0x1c, 0x64, 0x8c, 0x71, 0x08, 0x6c, //
    0x06, 0xe4, 0x82, 0x97, 0x1c, 0x60, 0x08, 0x54, 0x82, 0x97, 0x1c, 0x68, //
    0x22, 0x85, 0x02, 0x64, 0xa2, 0x60, 0x41, 0x01, 0x82, 0x87, //
  ],
  Abi.linuxRiscv32: [
    0x41, 0x11, 0x22, 0xc4, 0x2e, 0x84, 0x5c, 0x40, 0x8c, 0x49, 0x48, 0x44, //
    0x06, 0xc6, 0x82, 0x97, 0x1c, 0x40, 0x48, 0x48, 0x82, 0x97, 0x1c, 0x44, //
    0x22, 0x85, 0x22, 0x44, 0xb2, 0x40, 0x41, 0x01, 0x82, 0x87, //
  ],
};

// We need to attach the finalizer which calls close() and munmap().
final finalizerAddress = () {
  // UBSAN will dereference callback-8 to get typeinfo to check for matching
  // types at the call site for the finalizer callback. Make that slot
  // addressable and leave it initialized to NULL.
  final offset = 8;

  final Pointer<Uint8> finalizerStub = mmap(nullptr, kPageSize,
      kProtRead | kProtWrite, kMapPrivate | kMapAnon, -1, 0);
  finalizerStub
      .cast<Uint8>()
      .asTypedList(kPageSize)
      .setAll(offset, finalizerCode[Abi.current()]!);
  if (mprotect(finalizerStub, kPageSize, kProtRead | kProtExec) != 0) {
    throw 'Failed to write executable code to the memory.';
  }

  return finalizerStub.elementAt(offset).cast<Void>();
}();

base class PeerData extends Struct {
  external Pointer<Void> close;
  external Pointer<Void> munmap;
  external Pointer<Void> free;
  external Pointer<Uint8> mapping;
  @IntPtr()
  external int size;
  @IntPtr()
  external int fd;
}

Uint8List toExternalDataWithFinalizer(
    Pointer<Uint8> memory, int size, int length, int fd) {
  final Pointer<PeerData> peer = malloc.allocate<PeerData>(sizeOf<PeerData>());
  peer.ref.close = closeNative;
  peer.ref.munmap = munmapNative;
  peer.ref.free = freeNative;
  peer.ref.mapping = memory;
  peer.ref.size = size;
  peer.ref.fd = fd;
  return Dart_NewExternalTypedDataWithFinalizer(
    /*Dart_TypedData_kUint8*/ 2,
    memory.cast(),
    length,
    peer.cast(),
    size,
    finalizerAddress,
  ) as Uint8List;
}
