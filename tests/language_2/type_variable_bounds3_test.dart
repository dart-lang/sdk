// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized types with invalid bounds.

class A<K extends int> {}

class B<X, Y> {
  foo(x) {
    return x is A<X>;
    //       ^
    // [cfe] Type argument 'X' doesn't conform to the bound 'int' of the type variable 'K' on 'A'.
    //            ^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }
}

main() {
  var b = new B<double, double>();
  b.foo(new A());
}
