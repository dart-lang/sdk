// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Cloneable<T> {}

class Pair<T extends Cloneable<T>, U extends Cloneable<U>> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair._();
  Pair<U, T> get reversed => new /*@ typeArgs=Pair::U*, Pair::T* */ Pair(
      /*@target=Pair.u*/ u,
      /*@target=Pair.t*/ t);
}

main() {
  final /*@ type=Pair<Cloneable<dynamic>*, Cloneable<dynamic>*>* */ x =
      new /*error:COULD_NOT_INFER,error:COULD_NOT_INFER*/ /*@ typeArgs=Cloneable<dynamic>*, Cloneable<dynamic>* */ Pair
          ._();
}
