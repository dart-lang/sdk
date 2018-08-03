// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef V F<U, V>(U u);

class Foo<T> {
  Bar<T> get v1 => const /*@typeArgs=Null*/ Bar();
  Bar<List<T>> get v2 => const /*@typeArgs=List<Null>*/ Bar();
  Bar<F<T, T>> get v3 => const /*@typeArgs=(Object) -> Null*/ Bar();
  Bar<F<F<T, T>, T>> get v4 =>
      const /*@typeArgs=((Null) -> Object) -> Null*/ Bar();
  List<T> get v5 => /*@typeArgs=Null*/ const [];
  List<F<T, T>> get v6 => /*@typeArgs=(Object) -> Null*/ const [];
  Map<T, T> get v7 => /*@typeArgs=Null, Null*/ const {};
  Map<F<T, T>, T> get v8 => /*@typeArgs=(Object) -> Null, Null*/ const {};
  Map<T, F<T, T>> get v9 => /*@typeArgs=Null, (Object) -> Null*/ const {};
}

class Bar<T> {
  const Bar();
}

main() {}
