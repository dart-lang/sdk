// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that we invalidate parameter type optimization in the presence
// of optional parameters.

import "package:expect/expect.dart";

class A {
  void foo(bool firstInvocation, [a = 42, b = 'foo']) {
    if (firstInvocation) {
      Expect.isTrue(a is String);
      Expect.isTrue(b is int);
    } else {
      Expect.isTrue(a is int);
      Expect.isTrue(b is String);
    }
  }
}

test() {
  // This call to [A.foo] will be in the queue after [A.foo] has been
  // compiled with the optimistic type assumptions.
  new A().foo(false);
}

main() {
  test();
  // This call to [A.foo] will be the first in the queue, and dart2js
  // will optimize the method with these parameter types.
  new A().foo(true, 'bar', 42);
}
