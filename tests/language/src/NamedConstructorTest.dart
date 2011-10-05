// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NamedConstructorTest {
  int x_;

  NamedConstructorTest.fill(int x) {
    // Should resolve to the fill method
    fill(x);
  }

  void fill(int x) {
    x_ = x;
  }

  static testMain() {
    var a = new NamedConstructorTest.fill(3);
    assert(a.x_ == 3);
  }
}

main() {
  NamedConstructorTest.testMain();
}
