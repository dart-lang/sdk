// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  bool foo(T x) => true;
}

class B extends Object with A<B> {}

main() {
  var b = new B();
  Expect.isTrue(b is B);
  Expect.isTrue(b is A);

  // Verify that runtime checking enforces A<B> instead of A
  dynamic d = b;
  Expect.isTrue(d.foo(b));
  Expect.throws(() => d.foo(42));
}
