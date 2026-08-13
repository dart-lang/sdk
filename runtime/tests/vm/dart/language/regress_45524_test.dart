// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Reduced from:
// The Dart Project Fuzz Tester (1.89).
// Program generated as:
//   dart dartfuzz.dart --seed 3959760722 --no-fp --no-ffi --flat

bool var17 = bool.fromEnvironment('2y');

class X0 {
  num fld0_2 = 9223372036854775807;
}

extension XE0 on X0 {
  bool foo0_Extension0() {
    if (-12 >= -(((var17 ? -92 : fld0_2)))) {
      return true;
    } else {
      return false;
    }
  }
}

main() {
  Expect.equals(true, X0().foo0_Extension0());
}
