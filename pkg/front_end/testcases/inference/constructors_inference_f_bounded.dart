// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Clonable<T> {}

class Pair<T extends Clonable<T>, U extends Clonable<U>> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair._();
  Pair<U, T> get reversed => new /*@typeArgs=U, T*/ Pair(u, t);
}

main() {
  final /*@type=Pair<Clonable<dynamic>, Clonable<dynamic>>*/ x =
      new /*error:COULD_NOT_INFER,error:COULD_NOT_INFER*/ /*@typeArgs=Clonable<dynamic>, Clonable<dynamic>*/ Pair
          ._();
}
