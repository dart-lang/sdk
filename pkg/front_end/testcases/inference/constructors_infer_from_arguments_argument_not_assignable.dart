// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {}

typedef T F<T>();

class C<T extends A> {
  C(F<T> f);
}

class NotA {}

NotA myF() => null;

main() {
  var /*@type=C<NotA>*/ x =
      new /*error:COULD_NOT_INFER*/ /*@typeArgs=NotA*/ C(myF);
}
