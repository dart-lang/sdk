// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi dynamic library loading.

library FfiTest;

import 'dart:ffi' as ffi;

import 'package:expect/expect.dart';

void main() {
  testOpen();
  testOpenError();
  testLookup();
  testLookupError();
  testToString();
  testEquality();
}

void testOpen() {
  ffi.DynamicLibrary l = ffi.DynamicLibrary.open("ffi_test_dynamic_library");
  Expect.notEquals(null, l);
}

void testOpenError() {
  Expect.throws(
      () => ffi.DynamicLibrary.open("doesnotexistforsurelibrary123409876"));
}

typedef NativeDoubleUnOp = ffi.Double Function(ffi.Double);

typedef DoubleUnOp = double Function(double);

void testLookup() {
  ffi.DynamicLibrary l = ffi.DynamicLibrary.open("ffi_test_dynamic_library");
  var timesFour = l.lookupFunction<NativeDoubleUnOp, DoubleUnOp>("timesFour");
  Expect.approxEquals(12.0, timesFour(3));
}

void testLookupError() {
  ffi.DynamicLibrary l = ffi.DynamicLibrary.open("ffi_test_dynamic_library");
  Expect.throws(() => l.lookupFunction<NativeDoubleUnOp, DoubleUnOp>(
      "functionnamethatdoesnotexistforsure749237593845"));
}

void testToString() {
  ffi.DynamicLibrary l = ffi.DynamicLibrary.open("ffi_test_dynamic_library");
  Expect.stringEquals(
      "DynamicLibrary: handle=0x", l.toString().substring(0, 25));
}

void testEquality() {
  ffi.DynamicLibrary l = ffi.DynamicLibrary.open("ffi_test_dynamic_library");
  ffi.DynamicLibrary l2 = ffi.DynamicLibrary.open("ffi_test_dynamic_library");
  Expect.equals(l, l2);
  Expect.equals(l.hashCode, l2.hashCode);
  Expect.notEquals(l, null);
  Expect.notEquals(null, l);
  ffi.DynamicLibrary l3 = ffi.DynamicLibrary.open("ffi_test_functions");
  Expect.notEquals(l, l3);
}
