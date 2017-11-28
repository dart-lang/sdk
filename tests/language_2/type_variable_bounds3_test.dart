// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized types with invalid bounds.

class A<K extends int> {}

class B<X, Y> {
  foo(x) {
    return x is A<X>; // //# 00: compile-time error
  }
}

main() {
  var b = new B<double, double>();
  b.foo(new A());
}
