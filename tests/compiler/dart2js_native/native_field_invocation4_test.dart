// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

@Native("A")
class A {
  var foo;
}

class B {
  var foo;
}

nativeId(x) native;

void setup() native """
nativeId = function(x) { return x; }
""";

main() {
  setup();
  var b = new B();
  b.foo = (x) => x + 1;
  b = nativeId(b); // Inferrer doesn't know if A has been instantiated.
  // At this point b could be A or B. The call to "foo" thus needs to go through
  // an interceptor. Tests that the interceptor works for retrieving the field
  // and invoking the closure.
  // Use a type-check to guarantee that b is a "B".
  if (b is B) {
    Expect.equals(499, b.foo(498));
  }
}
