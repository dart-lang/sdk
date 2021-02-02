// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "package:expect/expect.dart";

import "coordinate.dart";

get is32Bit => 4 == sizeOf<IntPtr>();
get is64Bit => 8 == sizeOf<IntPtr>();

void main() async {
  if (is32Bit) {
    Expect.equals(4, sizeOf<Pointer>());
    Expect.equals(20, sizeOf<Coordinate>());
  }
  if (is64Bit) {
    Expect.equals(8, sizeOf<Pointer>());
    Expect.equals(24, sizeOf<Coordinate>());
  }
  Expect.throws(() => sizeOf<Void>());
}
