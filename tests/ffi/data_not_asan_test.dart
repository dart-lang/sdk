// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi primitive data pointers.
// This test tries to allocate too much memory on purpose to test the Exception
// thrown on malloc failing.
// This malloc also triggers an asan alarm, so this test is in a separate file
// which is excluded in asan mode.

library FfiTest;

import 'dart:ffi' as ffi;

import "package:expect/expect.dart";

void main() {
  testPointerAllocateTooLarge();
}

/// This test is skipped in asan mode.
void testPointerAllocateTooLarge() {
  int maxInt = 9223372036854775807; // 2^63 - 1
  Expect.throws(
      () => ffi.allocate<ffi.Int64>(count: maxInt)); // does not fit in range
  int maxInt1_8 = 1152921504606846975; // 2^60 -1
  Expect.throws(
      () => ffi.allocate<ffi.Int64>(count: maxInt1_8)); // not enough memory
}
