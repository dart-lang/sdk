// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--deterministic --optimization-counter-threshold=500 --enable-testing-pragmas
// VMOptions=--deterministic --optimization-counter-threshold=-1 --enable-testing-pragmas
// VMOptions=--deterministic --optimization-counter-threshold=500 --enable-testing-pragmas --no-dual-map-code --write-protect-code
// VMOptions=--deterministic --optimization-counter-threshold=-1 --enable-testing-pragmas --no-dual-map-code --write-protect-code
// VMOptions=--enable-testing-pragmas --no-dual-map-code --write-protect-code
// VMOptions=--enable-testing-pragmas --no-dual-map-code --write-protect-code --stacktrace-every=100
//
// Dart test program for stress-testing boxing and GC in return paths from FFI
// trampolines.
//
// NOTE: This test does not produce useful stderr when it fails because the
// stderr is redirected to a file for reflection.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi' as ffi;
import "package:expect/expect.dart";
import 'ffi_test_helpers.dart';

main() async {
  testBoxInt64();
  testBoxInt32();
  testBoxDouble();
  testBoxPointer();
  testAllocateInNative();
  testRegress37069();
  testWriteProtection();
}

typedef NativeNullaryOp64 = ffi.Int64 Function();
typedef NativeNullaryOp32 = ffi.Int32 Function();
typedef NativeNullaryOpDouble = ffi.Double Function();
typedef NativeNullaryOpPtr = ffi.Pointer<ffi.Void> Function();
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
  if (ffi.sizeOf<ffi.Pointer>() == 4) {
    Expect.equals(0x82000000, pointer.address);
  } else {
    Expect.equals(0x8100000082000000, pointer.address);
  }
}

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

final unprotectCode = ffiTestFunctions.lookupFunction<
    ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>),
    ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>)>("TestUnprotectCode");
final waitForHelper = ffiTestFunctions.lookupFunction<
    ffi.Void Function(ffi.Pointer<ffi.Void>),
    void Function(ffi.Pointer<ffi.Void>)>("WaitForHelper");

void testWriteProtection() {
  waitForHelper(unprotectCode(ffi.nullptr));
}
