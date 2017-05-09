// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  B<int> b;
}

class B<T> {
  B(T x);
}

var /*@topType=A*/ t1 = new A()..b = new /*@typeArgs=int*/ B(1);
var /*@topType=List<B<int>>*/ t2 = <B<int>>[new /*@typeArgs=int*/ B(2)];
var /*@topType=List<B<dynamic>>*/ t3 = /*@typeArgs=B<dynamic>*/ [
  new
      /*error:TOP_LEVEL_TYPE_ARGUMENTS*/ /*@typeArgs=dynamic*/ B(3)
];
