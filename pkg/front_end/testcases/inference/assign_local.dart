// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {}

class B<T> extends A<T> {}

main() {
  num x;
  var /*@type=int*/ x1 = (x = 1);
  var /*@type=double*/ x2 = (x = 1.0);

  // TODO(scheglov) uncomment when constructor inference is implemented.
//  A<int> y;
//  var /*@type=A<int>*/ y1 = (y = /*@typeArgs=int*/ new A());
//  var /*@type=B<int>*/ y2 = (y = /*@typeArgs=int*/ new B());
}
