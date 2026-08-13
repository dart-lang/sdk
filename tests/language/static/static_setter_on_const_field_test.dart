// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that static setters on const fields are properly invoked on set.

class A {
  static const int field = 0;
  static void set field(int value) {
    Expect.equals(value, 100);
    B.count += 1;
  }
}

class B {
  static int count = 0;
}

main() {
  Expect.equals(B.count, 0);
  A.field = 100;
  Expect.equals(B.count, 1);
  Expect.equals(A.field, 0);
  A.field = 100;
  Expect.equals(B.count, 2);
  Expect.equals(A.field, 0);
}
