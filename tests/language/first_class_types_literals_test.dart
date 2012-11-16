// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {}

class D {}

typedef int Foo(bool b);

sameType(a, b) {
  Expect.equals(a.runtimeType, b.runtimeType);
}

main() {
  // Test type literals.
  Expect.equals(int, int);
  Expect.notEquals(int, num);
  Expect.equals(Foo, Foo);

  // Test that class literals return instances of Type.
  Expect.isTrue((D).runtimeType is Type);

  // Test that types from runtimeType and literals agree.
  Expect.equals(int, 1.runtimeType);
  Expect.equals(C, new C().runtimeType);
  Expect.equals(D, new D().runtimeType);

  // runtimeType on type is idempotent.
  Expect.equals((D).runtimeType, (D).runtimeType.runtimeType);

  // Test that operator calls on class literals go to Type.
  Expect.throws(() => C = 1, (e) => e is NoSuchMethodError);
  Expect.throws(() => C++, (e) => e is NoSuchMethodError);
  Expect.throws(() => C + 1, (e) => e is NoSuchMethodError);
  Expect.throws(() => C[2], (e) => e is NoSuchMethodError);
  Expect.throws(() => C[2] = 'hest', (e) => e is NoSuchMethodError);
}
