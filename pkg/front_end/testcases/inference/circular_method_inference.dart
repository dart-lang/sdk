// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// The following code is illegal because it has a loop in the class hierarchy.
// We need to make sure that the compiler doesn't try to error recover in a way
// that causes type inference for the method `f` to go into an infinite loop.

abstract class A extends B {
  /*@topType=dynamic*/ f(/*@topType=dynamic*/ x);
}

abstract class B extends A {
  /*@topType=dynamic*/ f(/*@topType=dynamic*/ x);
}

main() {}
