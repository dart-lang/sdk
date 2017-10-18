// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A {
  void set x(num value);
}

abstract class B extends A {
  int get x;
}

// The getter in B doesn't screen the setter in A, so inference sees two
// different types and gives an error.
class C extends B {
  var /*@topType=int*/ x;
}

main() {}
