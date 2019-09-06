// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void foo(F f<F>(F f)) {}

B bar<B>(B g<F>(F f)) => null;

Function baz<B>() {
  B foo<F>(B b, F f) => null;
  return foo;
}

class C<T> {
  void foo(F f<F>(T t, F f)) => null;
  B bar<B>(B g<F>(T t, F f)) => null;
  Function baz<B>() {
    B foo<F>(T t, F f) => null;
    return foo;
  }
}

main() {
  // Check the run-time type of the functions with generic parameters.

  Expect.type<void Function(X Function<X>(X))>(foo);

  Expect.isTrue(bar is X1 Function<X1>(X1 Function<X2>(X2)));

  Expect.isTrue(baz<int>() is int Function<X1>(int, X1));
  Expect.isTrue(baz<Object>() is Object Function<X1>(Object, X1));
  Expect.isTrue(baz<Null>() is Null Function<X1>(Null, X1));

  void testC<T>() {
    var c = new C<T>();

    Expect.type<void Function(F Function<F>(T, F))>(c.foo);

    Expect.isTrue(c.bar is X1 Function<X1>(X1 Function<X2>(T, X2)));

    Expect.isTrue(c.baz<int>() is int Function<X1>(T, X1));
  }

  testC<bool>();
  testC<Object>();
  testC<Null>();
}
