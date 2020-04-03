// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class C {}

abstract class D<T> {
  D(T t);
}

void test() {
  var /*@type=dynamic*/ x = new C();
  var /*@type=dynamic*/ y = new D(1);
  D<List<int>> z = new D(/*@typeArgs=dynamic*/ []);
}

main() {}
