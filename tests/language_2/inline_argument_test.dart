// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that when inlining A.foo, we're not evaluating the argument
// twice.

import "package:expect/expect.dart";

class A {
  var field = 0;

  foo(b) {
    Expect.equals(0, b);
    Expect.equals(0, b);
  }

  bar() {
    foo(field++);
  }
}

main() {
  var a = new A();
  a.bar();
  Expect.equals(1, a.field);
}
