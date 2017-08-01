// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

import "package:expect/expect.dart";

typedef int H(
    Function
    Function //# 00: compile-time error
        x);

main() {
  bool b = true;
  Expect.isFalse(b is H);
}
