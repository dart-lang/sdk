// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef V F<U, V>(U u);

class Foo<T> {
  Bar<T> get v1 => new /*@typeArgs=Foo::T*/ Bar();
  Bar<List<T>> get v2 => new /*@typeArgs=List<Foo::T>*/ Bar();
  Bar<F<T, T>> get v3 => new /*@typeArgs=(Foo::T) -> Foo::T*/ Bar();
  Bar<F<F<T, T>, T>> get v4 =>
      new /*@typeArgs=((Foo::T) -> Foo::T) -> Foo::T*/ Bar();
  List<T> get v5 => /*@typeArgs=Foo::T*/ [];
  List<F<T, T>> get v6 => /*@typeArgs=(Foo::T) -> Foo::T*/ [];
  Map<T, T> get v7 => /*@typeArgs=Foo::T, Foo::T*/ {};
  Map<F<T, T>, T> get v8 => /*@typeArgs=(Foo::T) -> Foo::T, Foo::T*/ {};
  Map<T, F<T, T>> get v9 => /*@typeArgs=Foo::T, (Foo::T) -> Foo::T*/ {};
}

class Bar<T> {
  const Bar();
}

main() {}
