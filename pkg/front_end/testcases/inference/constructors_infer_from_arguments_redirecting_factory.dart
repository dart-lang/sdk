// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class C<T> {
  T get t;
  void set t(T x);

  factory C(T t) = CImpl<T>;
}

class CImpl<T> implements C<T> {
  T t;
  CImpl(this.t);
}

main() {
  var /*@type=C<int>*/ x = new /*@typeArgs=int*/ C(42);
}
