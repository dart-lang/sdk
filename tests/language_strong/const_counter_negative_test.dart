// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Bug: 4254106 Constant constructors must have (implicit) const parameters.

import "package:expect/expect.dart";

class ConstCounter {
  // Incorrect assignment of a non const function to a final field.
  const ConstCounter(int i) : nextValue_ = (() => i++);

  final nextValue_;

  int nextValue() {
    return nextValue_();
  }
}

class ConstCounterNegativeTest {
  static testMain() {
    ConstCounter cc = const ConstCounter(3);
    Expect.equals(3, cc.nextValue());
  }
}

main() {
  ConstCounterNegativeTest.testMain();
}
