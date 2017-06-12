// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  T t;
  C();

  factory C.named(T t) {
    var /*@type=C<T>*/ x = new C<T>();
    x.t = t;
    return x;
  }
}

main() {
  var /*@type=C<int>*/ x = new /*@typeArgs=int*/ C.named(42);
}
