// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// File is compiled with checked in SDK, update [FfiNative]s to [Native] when
// SDK is rolled.

// ignore_for_file: camel_case_types
// ignore_for_file: deprecated_member_use
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// int open(const char *path, int oflag, ...);
@Native<Int32 Function(Pointer<Utf8>, Int32)>(symbol: "open")
external int open(Pointer<Utf8> filename, int flags);

// int close(int fd);
@Native<Int32 Function(Int32)>(symbol: "close")
external int close(int fd);

// void* mmap(void* addr, size_t length,
//            int prot, int flags,
//            int fd, off_t offset)
@FfiNative<
    Pointer<Uint8> Function(
        Pointer<Uint8>, IntPtr, Int32, Int32, Int32, IntPtr)>("mmap")
external Pointer<Uint8> mmap(
    Pointer<Uint8> address, int len, int prot, int flags, int fd, int offset);

// int munmap(void *addr, size_t length)
@Native<IntPtr Function(Pointer<Uint8> address, IntPtr len)>(symbol: "munmap")
external int munmap(Pointer<Uint8> address, int len);

final DynamicLibrary processSymbols = DynamicLibrary.process();
final munmapNative = processSymbols.lookup<Void>('munmap');
final closeNative = processSymbols.lookup<Void>('close');
final freeNative = processSymbols.lookup<Void>('free');

// int mprotect(void *addr, size_t len, int prot)
@Native<Int32 Function(Pointer<Uint8>, IntPtr, Int32)>(symbol: "mprotect")
external int mprotect(Pointer<Uint8> addr, int len, int prot);

// DART_EXPORT Dart_Handle
// Dart_NewExternalTypedDataWithFinalizer(Dart_TypedData_Type type,
//                                       void* data,
//                                       intptr_t length,
//                                       void* peer,
//                                       intptr_t external_allocation_size,
//                                       Dart_HandleFinalizer callback)
typedef Dart_NewExternalTypedDataWithFinalizerNative = Handle Function(
    Int32, Pointer<Void>, IntPtr, Pointer<Void>, IntPtr, Pointer<Void>);
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

// We need to attach the finalizer which calls close() and

final finalizerAddress = () {
  final Pointer<Uint8> finalizerStub = mmap(nullptr, kPageSize,
      kProtRead | kProtWrite, kMapPrivate | kMapAnon, -1, 0);
  finalizerStub.cast<Uint8>().asTypedList(kPageSize).setAll(0, <int>[
// Regenerate by running dart mmap.dart gen
// ASM_START
//    #include <cstddef>
//    #include <cstdint>
//
//    struct PeerData {
//        int (*close)(int);
//        int (*munmap)(void*, size_t);
//        int (*free)(void*);
//        void* mapping;
//        intptr_t size;
//        intptr_t fd;
//    };
//
//    extern "C" void finalizer(void* callback_data, void* peer) {
//        auto data = static_cast<PeerData*>(peer);
//        data->munmap(data->mapping, data->size);
//        data->close(data->fd);
//        data->free(peer);
//    }
//
    0x55, 0x48, 0x89, 0xf5, 0x48, 0x8b, 0x76, 0x20, 0x48, 0x8b, 0x7d, 0x18, //
    0xff, 0x55, 0x08, 0x8b, 0x7d, 0x28, 0xff, 0x55, 0x00, 0x48, 0x8b, 0x45, //
    0x10, 0x48, 0x89, 0xef, 0x5d, 0xff, 0xe0, //
// ASM_END
  ]);
  if (mprotect(finalizerStub, kPageSize, kProtRead | kProtExec) != 0) {
    throw 'Failed to write executable code to the memory.';
  }

  return finalizerStub.cast<Void>();
}();

class PeerData extends Struct {
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
