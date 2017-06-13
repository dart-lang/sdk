// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Pair<T, U> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair<U, T> get reversed => new /*@typeArgs=Pair::U, Pair::T*/ Pair(
      /*@target=Pair::u*/ u,
      /*@target=Pair::t*/ t);
}

main() {}
