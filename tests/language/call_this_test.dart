// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js treats [:this():] as a closure send.

import "package:expect/expect.dart";

class A {
  call() => 42;
  test1() => this();
  test2() => (this)();
}

main() {
  Expect.equals(42, (new A()).test1());
  Expect.equals(42, (new A()).test2());
}
