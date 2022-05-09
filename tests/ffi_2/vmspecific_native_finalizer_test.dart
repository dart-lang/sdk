// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// @dart = 2.9

import 'dart:ffi';
import 'dart:io';

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

void main() {
  testMallocFree();
  print('end of test, shutting down');
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

void testMallocFree() {
  if (Platform.isWindows) {
    // malloc and free not supported.
    return;
  }

  print('freePtr $freePtr');

  {
    final resource = MyNativeResource();
    resource.close();
    doGC();
  }

  {
    MyNativeResource();
    doGC();
  }

  // Run finalizer on shutdown (or on a GC that runs before shutdown).
  MyNativeResource();
}

class MyNativeResource implements Finalizable {
  final Pointer<Void> pointer;

  bool _closed = false;

  MyNativeResource._(this.pointer, {int externalSize}) {
    print('pointer $pointer');
    freeFinalizer.attach(this, pointer,
        externalSize: externalSize, detach: this);
  }

  factory MyNativeResource() {
    const num = 1;
    const size = 16;
    final pointer = calloc(num, size);
    return MyNativeResource._(pointer, externalSize: size);
  }

  /// Eagerly stop using the native resource. Cancelling the finalizer.
  void close() {
    _closed = true;
    freeFinalizer.detach(this);
    free(pointer);
  }

  void useResource() {
    if (_closed) {
      throw UnsupportedError('The native resource has already been released');
    }
    print(pointer.address);
  }
}

final DynamicLibrary stdlib = DynamicLibrary.process();

typedef PosixCallocNative = Pointer<Void> Function(IntPtr num, IntPtr size);
typedef PosixCalloc = Pointer<Void> Function(int num, int size);
final PosixCalloc calloc =
    stdlib.lookupFunction<PosixCallocNative, PosixCalloc>('calloc');

typedef PosixFreeNative = Void Function(Pointer<Void>);
final freePtr = stdlib.lookup<NativeFunction<PosixFreeNative>>('free');
final free = freePtr.asFunction<void Function(Pointer<Void>)>();

final freeFinalizer = NativeFinalizer(freePtr);
