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
  var /*@type=C*/ x = new C();
  var /*@type=D<int>*/ y = new /*@typeArgs=int*/ D(1);
  D<List<int>> z = new /*@typeArgs=List<int>*/ D(/*@typeArgs=int*/ []);
}

main() {}
