// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {
  A(B<List<T>> b);
}

class B<T> {}

main() {
  var /*@type=A<dynamic>*/ x =
      new /*@typeArgs=dynamic*/ A(new /*@typeArgs=List<dynamic>*/ B());
}
