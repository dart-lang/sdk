// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers.
//
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=10
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--write-protect-code --no-dual-map-code
// VMOptions=--write-protect-code --no-dual-map-code --use-slow-path
// VMOptions=--write-protect-code --no-dual-map-code --stacktrace-every=100
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

import "package:ffi/ffi.dart";
import "package:expect/expect.dart";

void main() {
  for (int i = 0; i < 100; ++i) {
    testLookupFunctionPointerNativeType();
  }
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef NativeTypeNFT = Pointer<NativeType> Function(
    Pointer<Pointer<NativeType>>, Int8);
typedef NativeTypeFT = Pointer<NativeType> Function(
    Pointer<Pointer<NativeType>>, int);

void testLookupFunctionPointerNativeType() {
  // The function signature does not match up, but that does not matter since
  // this test does not use the trampoline.
  ffiTestFunctions.lookupFunction<NativeTypeNFT, NativeTypeFT>("LargePointer");
}
