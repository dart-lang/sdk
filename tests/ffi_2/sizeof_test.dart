// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";

import "coordinate.dart";

get is32Bit => 4 == sizeOf<IntPtr>();
get is64Bit => 8 == sizeOf<IntPtr>();

void main() async {
  if (is32Bit) {
    Expect.equals(4, sizeOf<Pointer>());
    // Struct is 20 bytes on ia32 and arm32-iOS, but 24 bytes on arm32-Android
    // and arm32-Linux due to alignment.
    Expect.isTrue(20 == sizeOf<Coordinate>() || 24 == sizeOf<Coordinate>());
  } else if (is64Bit) {
    Expect.equals(8, sizeOf<Pointer>());
    Expect.equals(24, sizeOf<Coordinate>());
  }
  Expect.throws(() => sizeOf<Void>());
}
