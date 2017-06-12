// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a loop invariant code motion optimization correctly hoists
// instructions that may cause deoptimization.

import "package:expect/expect.dart";

foo(o) {
  var r = 0;
  for (var i = 0; i < 3; i++) {
    r += o.z;
  }
  return r;
}

class A {
  var z = 3;
}

main() {
  var a = new A();
  for (var i = 0; i < 10000; i++) foo(a);
  Expect.equals(9, foo(a));
  Expect.throws(() => foo(42));
  for (var i = 0; i < 10000; i++) foo(a);
  Expect.throws(() => foo(42));
}
