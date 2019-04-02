// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--deterministic --optimization-counter-threshold=500 --verbose-gc
// VMOptions=--deterministic --optimization-counter-threshold=-1 --verbose-gc
//
// Dart test program for stress-testing boxing and GC in return paths from FFI
// trampolines.
//
// NOTE: This test does not produce useful stderr when it fails because the
// stderr is redirected to a file for reflection.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi' as ffi;
import 'dylib_utils.dart';
import "package:expect/expect.dart";
import 'gc_helper.dart';

test(GCWatcher watcher, void Function() testee,
    {bool mustTriggerGC: true}) async {
  // Warmup.
  for (int i = 0; i < 1000; ++i) {
    testee();
  }
  int size = await watcher.size();
  for (int i = 0; i < 1000000; ++i) {
    testee();
  }
  int new_size = await watcher.size();
  if (mustTriggerGC) {
    print("Expect $new_size > $size.");
    Expect.isTrue(new_size > size);
  }
}

main() async {
  final watcher = GCWatcher.ifAvailable();
  try {
    await test(watcher, testBoxInt64);
    // On 64-bit platforms this won't trigger GC because the result fits into a
    // Smi.
    await test(watcher, testBoxInt32, mustTriggerGC: false);
    await test(watcher, testBoxDouble);
    await test(watcher, testBoxPointer);
  } finally {
    watcher.dispose();
  }
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

typedef NativeNullaryOp64 = ffi.Int64 Function();
typedef NativeNullaryOp32 = ffi.Int32 Function();
typedef NativeNullaryOpDouble = ffi.Double Function();
typedef NativeNullaryOpPtr = ffi.Pointer<ffi.Void> Function();
typedef NullaryOp = int Function();
typedef NullaryOpDbl = double Function();
typedef NullaryOpPtr = ffi.Pointer<ffi.Void> Function();

//// These functions return values that require boxing into different types.

final minInt64 =
    ffiTestFunctions.lookupFunction<NativeNullaryOp64, NullaryOp>("MinInt64");

// Forces boxing into Mint on all platforms.
void testBoxInt64() {
  Expect.equals(0x8000000000000000, minInt64());
}

NullaryOp minInt32 =
    ffiTestFunctions.lookupFunction<NativeNullaryOp32, NullaryOp>("MinInt32");

// Forces boxing into Mint on 32-bit platforms only.
void testBoxInt32() {
  Expect.equals(-0x80000000, minInt32());
}

final smallDouble = ffiTestFunctions
    .lookupFunction<NativeNullaryOpDouble, NullaryOpDbl>("SmallDouble");

// Forces boxing into Double.
void testBoxDouble() {
  Expect.equals(0x80000000 * -1.0, smallDouble());
}

final largePointer = ffiTestFunctions
    .lookupFunction<NativeNullaryOpPtr, NullaryOpPtr>("LargePointer");

// Forces boxing into ffi.Pointer and ffi.Mint.
void testBoxPointer() {
  ffi.Pointer pointer = largePointer();
  if (pointer != null) {
    if (ffi.sizeOf<ffi.Pointer>() == 4) {
      Expect.equals(0x82000000, pointer.address);
    } else {
      Expect.equals(0x8100000082000000, pointer.address);
    }
  }
}
