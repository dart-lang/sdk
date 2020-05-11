// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  foo() => 23;
}

extension B on A? {
  foo() => 42;
  bar() => 87;
}

extension C on A {
  bar() => 123;
}

extension D on int Function()? {
  int call() => 76;
}

main() {
  testA(new A());
  testFunction(() => 53);
}

testA(A? a) {
  expect(23, a?.foo()); // A.foo instead of B.foo.
  expect(42, a.foo()); // B.foo instead of nullable access to A.foo.
  expect(123, a?.bar()); // C.bar instead of B.bar.
  expect(87, a.bar()); // B.bar instead of nullable access to C.bar.
}

testFunction(int Function()? f) {
  expect(53, f?.call()); // Function.call instead of D.call.
  expect(76, f.call()); // D.call instead of nullable access to Function.call.
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
