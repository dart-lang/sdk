// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A {
  num get x;
}

abstract class B extends A {
  void set x(int value);
}

// The getter in B doesn't screen the setter in A, so inference sees two
// different types and gives an error.
class C extends B {
  var /*@topType=num*/ x;
}

main() {}
