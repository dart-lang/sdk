// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi with null values.
//
// Separated into a separate file to make NNBD testing easier.
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

void main() {
  testOpen();
  testEquality();
}

void testOpen() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  Expect.notEquals(null, l);
}

typedef NativeDoubleUnOp = Double Function(Double);

typedef DoubleUnOp = double Function(double);

void testEquality() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  Expect.notEquals(l, null);
  Expect.notEquals(null, l);
}
