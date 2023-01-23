// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--intrinsify
// VMOptions=--no_intrinsify

import 'package:expect/expect.dart';

main() {
  // We do not guarantee any particular hash function for integers,
  // but our implementation relies on the hash function being the same
  // across architectures.
  <int, int>{
    0: 0x0,
    -0: 0x0,
    1: 0x2d51,
    -1: 0x0,
    0xffff: 0x2d50d2af,
    -0xffff: 0x2d50fffe,
    0xffffffff: 0x3fffffff,
    -0xffffffff: 0x3fffd2ae,
    0x111111111111: 0x25630507,
    -0x111111111111: 0x25632856,
    0xffffffffffff: 0x12af2d50,
    -0xffffffffffff: 0x12af0001,
    9007199254840856: 0x2f2da59d,
    144115188075954880: 0x26761e9a,
    936748722493162112: 0x196ac8cd,
  }.forEach((value, expected) {
    Expect.equals(expected, value.hashCode, "${value}.hashCode");
  });
}
