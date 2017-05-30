// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {
  A(T x);
}

var /*@topType=List<A<int>>*/ t1 = <A<int>>[new /*@typeArgs=int*/ A(1)];
var /*@topType=List<A<dynamic>>*/ t2 = /*@typeArgs=A<dynamic>*/ [
  new
      /*error:TOP_LEVEL_TYPE_ARGUMENTS*/ /*@typeArgs=dynamic*/ A(2)
];

main() {}
