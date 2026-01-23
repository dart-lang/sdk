// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

// SharedObjects=ffi_test_functions

import 'dart:ffi';

// We want at least 1 mapping to satisfy the static checks.
const notTestingOn = Abi.fuchsiaArm64;

@AbiSpecificIntegerMapping({
  notTestingOn: Int8(),
})
final class Incomplete extends AbiSpecificInteger {
  const Incomplete();
}

void main() {
  // Any use that causes the class to be used, causes a compile-time error
  // during loading of the class.
  nullptr.cast<Incomplete>(); // [cfe] Class 'Incomplete' does not have an AbiSpecificIntegerMapping for the current platform.
}
