// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that an object when thrown stays the same.

class A {
  A();
}

check(exception) {
  try {
    throw exception;
  } catch (e) {
    Expect.equals(exception, e);
  }
}

main() {
  check("str");
  check(new A());
  check(1);
  check(1.2);
}
