// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}

class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
}

void main() {
  /*@typeArgs=dynamic*/ new F3(/*@typeArgs=Iterable<dynamic>*/ []);
  /*@typeArgs=dynamic*/ new F4(a: /*@typeArgs=Iterable<dynamic>*/ []);
}
