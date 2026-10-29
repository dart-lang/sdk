// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/static_type_helper.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/64517.

typedef F<T> = void Function<S>(S, T);

class C<T> {
  void foo<S>(S s, T t) {}

  void testStaticType<S>(Type expected) {
    // The static type of `v` is `void Function<S'>(S', S)` where `S'` is the
    // type parameter of the torn off `foo` and `S` is the type parameter of
    // `testStaticType`.
    var v = C<S>().foo;
    v.expectStaticType<Exactly<void Function<X>(X, S)>>();
    Expect.equals(expected, v.staticType);
    Expect.equals(typeOf<void Function<X>(X, S)>(), v.staticType);
    Expect.notEquals(typeOf<void Function<X>(X, X)>(), v.staticType);
    Expect.notEquals(typeOf<void Function<X>(X, T)>(), v.staticType);
  }
}

void testEnclosingTypeParameterNotCaptured<S>(Type expected) {
  // `F<S>` is `void Function<S'>(S', S)` where `S` is the type parameter of
  // this function.
  void g<X>(X x, S s) {}
  F<S> f = g;
  f.expectStaticType<Exactly<void Function<X>(X, S)>>();
  Expect.equals(expected, f.staticType);
  Expect.equals(typeOf<void Function<X>(X, S)>(), f.staticType);
  Expect.notEquals(typeOf<void Function<X>(X, X)>(), f.staticType);
}

void main() {
  C<String>().testStaticType<int>(typeOf<void Function<X>(X, int)>());
  C<int>().testStaticType<String>(typeOf<void Function<X>(X, String)>());

  testEnclosingTypeParameterNotCaptured<int>(
    typeOf<void Function<X>(X, int)>(),
  );
  testEnclosingTypeParameterNotCaptured<String>(
    typeOf<void Function<X>(X, String)>(),
  );
}
