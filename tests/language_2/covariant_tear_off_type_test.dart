// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef U F<T, U>(T x);

class C<T> {
  T f(List<T> x) {}
}

F<List<num>, num> g(C<num> c) {
  return c.f;
}

void main() {
  var tearoff = g(new C<int>());
  // Since C.f's x parameter is covariant, its type is changed to Object when
  // determining the type of the tearoff.  So the type of the tearoff should be
  // `(Object) -> int`.  (Not, for example, `(List<Object>) -> int` or
  // `(List<Object>) -> Object`)
  Expect.isTrue(tearoff is F<Object, int>);
  // Because the function accepts any object, we can pass strings to it.  This
  // will not work in Dart 1.
  Expect.isTrue(tearoff is F<String, int>);
}
