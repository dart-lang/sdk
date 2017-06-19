// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {
  final T x = null;
  final T w = null;
}

class B implements A<int> {
  get /*@topType=int*/ x => 3;
  get /*@topType=int*/ w => /*error:RETURN_OF_INVALID_TYPE*/ "hello";
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/ new B(). /*@target=B::x*/ x;
  int z = new B(). /*@target=B::x*/ x;
}

main() {
  foo();
}
