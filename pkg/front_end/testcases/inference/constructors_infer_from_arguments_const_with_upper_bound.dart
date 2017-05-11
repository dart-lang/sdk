// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T extends num> {
  final T x;
  const C(this.x);
}

class D<T extends num> {
  const D();
}

void f() {
  const /*@type=C<int>*/ c = const /*@typeArgs=int*/ C(0);
  C<int> c2 = c;
  const D<int> d = const /*@typeArgs=int*/ D();
}
