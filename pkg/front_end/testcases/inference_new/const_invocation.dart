// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef V F<U, V>(U u);

class Foo<T> {
  Bar<T> get v1 => const /*@typeArgs=Never*/ Bar();
  Bar<List<T>> get v2 => const /*@typeArgs=List<Never>*/ Bar();
  Bar<F<T, T>> get v3 => const /*@typeArgs=(Object?) -> Never*/ Bar();
  Bar<F<F<T, T>, T>> get v4 =>
      const /*@typeArgs=((Never) -> Object?) -> Never*/ Bar();
  List<T> get v5 => /*@typeArgs=Never*/ const [];
  List<F<T, T>> get v6 => /*@typeArgs=(Object?) -> Never*/ const [];
  Map<T, T> get v7 => /*@typeArgs=Never, Never*/ const {};
  Map<F<T, T>, T> get v8 => /*@typeArgs=(Object?) -> Never, Never*/ const {};
  Map<T, F<T, T>> get v9 => /*@typeArgs=Never, (Object?) -> Never*/ const {};
}

class Bar<T> {
  const Bar();
}

main() {}
