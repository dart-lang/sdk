// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  @override
  Type get runtimeType => B;
}

class B extends A {
  @override
  Type get runtimeType => A;
}

Type typeObject<T>() => T;

main() {
  final a = A();
  final b = B();

  Expect.isTrue(a is A);
  Expect.isFalse(a is B);
  Expect.isTrue(b is A);
  Expect.isTrue(b is B);

  Expect.isTrue((a,) is (A,));
  Expect.isFalse((a,) is (B,));
  Expect.isTrue((b,) is (A,));
  Expect.isTrue((b,) is (B,));

  Expect.equals(typeObject<B>(), a.runtimeType);
  Expect.equals(typeObject<A>(), b.runtimeType);

  Expect.equals(typeObject<(A,)>(), (a,).runtimeType);
  Expect.equals(typeObject<(B,)>(), (b,).runtimeType);
}
