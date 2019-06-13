// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--deterministic --optimization-counter-threshold=500 --enable-testing-pragmas
// VMOptions=--deterministic --optimization-counter-threshold=-1 --enable-testing-pragmas
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

main() async {
  testBoxInt64();
  testBoxInt32();
  testBoxDouble();
  testBoxPointer();
  testAllocateInNative();
  testAllocateInDart();
  testRegress37069(); //# regress: ok
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

typedef NativeNullaryOp64 = ffi.Int64 Function();
typedef NativeNullaryOp32 = ffi.Int32 Function();
typedef NativeNullaryOpDouble = ffi.Double Function();
typedef NativeNullaryOpPtr = ffi.Pointer<ffi.Void> Function();
typedef NativeNullaryOp = ffi.Void Function();
typedef NativeUnaryOp = ffi.Void Function(ffi.Uint64);
typedef NativeUndenaryOp = ffi.Uint64 Function(
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64,
    ffi.Uint64);
typedef NullaryOp = int Function();
typedef NullaryOpDbl = double Function();
typedef NullaryOpPtr = ffi.Pointer<ffi.Void> Function();
typedef UnaryOp = void Function(int);
typedef NullaryOpVoid = void Function();
typedef UndenaryOp = int Function(
    int, int, int, int, int, int, int, int, int, int, int);

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

final triggerGc = ffiTestFunctions
    .lookupFunction<NativeNullaryOp, NullaryOpVoid>("TriggerGC");

// Test GC in the FFI call path by calling a C function which triggers GC
// directly.
void testAllocateInNative() => triggerGc();
// This also works as a regression test for 37176.

final regress37069 = ffiTestFunctions
    .lookupFunction<NativeUndenaryOp, UndenaryOp>("Regress37069");

// Test GC in the FFI call path by calling a C function which triggers GC
// directly.
void testRegress37069() {
  regress37069(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
}

class C {
  final int i;
  C(this.i);
}

@pragma("vm:entry-point", "call")
void testAllocationsInDartHelper() => triggerGc();

final allocateThroughDart = ffiTestFunctions
    .lookupFunction<NativeNullaryOp, NullaryOpVoid>("AllocateThroughDart");

// Test GC in the FFI call path by calling a C function which allocates by
// calling back into Dart ('testAllocationsInDartHelper').
void testAllocateInDart() => allocateThroughDart();
