// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=150

import "package:expect/expect.dart";
import "package:expect/variations.dart";

class A<T> {}

class B<T> {
  void foo(T x) {}
  void bar(A<T> x) {}
}

class C {
  void baz(Object? x) {}
}

class D1 implements C {
  void baz(covariant A<int> x) {}
}

class D2 implements C {
  void baz(covariant A<(int, int)> x) {}
}

B<(num, num)> b1 = (int.parse('1') == 1) ? B<(int, int)>() : B<(num, num)>();
B<({num foo})?> b2 =
    (int.parse('1') == 1) ? B<({int foo})>() : B<({num foo})?>();
B<(num?, {num? foo})?> b3 =
    (int.parse('1') == 1) ? B<(int, {int? foo})?>() : B<(num?, {num? foo})?>();
C d1 = (int.parse('1') == 1) ? D1() : C();
C d2 = (int.parse('1') == 1) ? D2() : C();

doTests() {
  b1.foo((1, 2));
  Expect.throwsTypeError(() => b1.foo((1.5, 2)));
  Expect.throwsTypeError(() => b1.foo((1, 2.5)));

  b1.bar(A<(int, int x)>());
  b1.bar(A<Never>());
  Expect.throwsTypeError(() => b1.bar(A<(int, double)>()));
  Expect.throwsTypeError(() => b1.bar(A<(num, int)>()));

  b2.foo((foo: 10));
  Expect.throwsTypeError(() => b2.foo((foo: 10.5)));
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() => b2.foo(null));
  }

  b2.bar(A<({int foo})>());
  b2.bar(A<Never>());
  Expect.throwsTypeError(() => b2.bar(A<({num foo})>()));
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() => b2.bar(A<Null>()));
    Expect.throwsTypeError(() => b2.bar(A<({int foo})?>()));
  }

  b3.foo((20, foo: 30));
  b3.foo((20, foo: null));
  b3.foo(null);
  Expect.throwsTypeError(() => b3.foo((20.5, foo: 30)));
  Expect.throwsTypeError(() => b3.foo((20, foo: 30.5)));
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() => b3.foo((null, foo: 30)));
  }

  b3.bar(A<(int, {int foo})>());
  b3.bar(A<(int, {int? foo})>());
  b3.bar(A<(int, {int? foo})?>());
  b3.bar(A<Null>());
  b3.bar(A<Never>());
  Expect.throwsTypeError(() => b3.bar(A<(int, {double foo})>()));
  Expect.throwsTypeError(() => b3.bar(A<(num, {int foo})>()));
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() => b3.bar(A<(int?, {int? foo})?>()));
  }

  d1.baz(A<int>());
  Expect.throwsTypeError(() => d1.baz(A<(int, int)>()));
  d2.baz(A<(int, int)>());
  Expect.throwsTypeError(() => d2.baz(A<int>()));
}

main() {
  for (int i = 0; i < 200; ++i) {
    doTests();
  }
}
