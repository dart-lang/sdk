// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;

main() {
  var /*@type=(num) -> List<int>*/ v = /*@typeArgs=(num) -> List<int>*/ generic(
      /*@returnType=dynamic*/ (F f) => null,
      /*@returnType=dynamic*/ (G g) => null);
}
