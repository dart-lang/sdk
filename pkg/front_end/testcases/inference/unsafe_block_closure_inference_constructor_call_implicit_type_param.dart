// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  C(T x());
}

main() {
  var /*@type=C<int>*/ v = new /*@typeArgs=int*/ C(
      /*@returnType=int*/ () {
    return 1;
  });
}
