// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.

class C {
  final var a;  // illegal field declaration.
}


class Field3NegativeTest {
  static testMain() {
  }
}

main() {
  Field3NegativeTest.testMain();
}
