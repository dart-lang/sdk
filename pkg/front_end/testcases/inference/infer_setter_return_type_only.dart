// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  void set x(int i) {}
}

class B extends A {
  // The setter return type should be inferred, but the setter parameter type
  // should not.
  set x(Object o) {}
}

main() {
  // Ok because the setter accepts `Object`.
  new B(). /*@target=B.x*/ x = "hello";
}
