// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to consider that the
// intersection of [Comparable] and [num] is conflicting.

import "package:expect/expect.dart";

class A {
  foo(a, Comparable b) => a == b;
  bar(a, Comparable b) => b == a;
}

main() {
  Expect.isFalse(new A().foo(1, 'foo'));
  Expect.isTrue(new A().foo(1, 1));
  Expect.isFalse(new A().bar(1, 'foo'));
  Expect.isTrue(new A().bar(1, 1));
}
