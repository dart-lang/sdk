// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {}

class D {}

typedef int Foo(bool b);

sameType(a, b) {
  Expect.identical(a.runtimeType, b.runtimeType);
}

differentType(a, b) {
  print("a: ${a.runtimeType}");
  print("b: ${b.runtimeType}");
  Expect.isFalse(a.runtimeType === b.runtimeType);
}

main() {
  // Test type literals.
  Expect.identical(int, int);
  Expect.isFalse(int === num);
  Expect.identical(Foo, Foo);

  // Test that class literals return instances of Type.
  Expect.isTrue((D).runtimeType is Type);

  // Test that types from runtimeType and literals agree.
  Expect.identical(int, 1.runtimeType);
  Expect.identical(C, new C().runtimeType);
  Expect.identical(D, new D().runtimeType);

  // runtimeType on type is idempotent.
  Expect.identical((D).runtimeType, (D).runtimeType.runtimeType);

  // Test that operator calls on class literals go to Type.
  Expect.throws(() => C = 1, (e) => e is NoSuchMethodError);
  Expect.throws(() => C++, (e) => e is NoSuchMethodError);
  Expect.throws(() => C + 1, (e) => e is NoSuchMethodError);
  Expect.throws(() => C[2], (e) => e is NoSuchMethodError);
  Expect.throws(() => C[2] = 'hest', (e) => e is NoSuchMethodError);
}
