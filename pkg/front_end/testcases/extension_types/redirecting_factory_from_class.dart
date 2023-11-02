// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  final int foo;
  const A1(this.foo);
  const factory A1.redir(A1 it) = E1.redir;
}

extension type const E1(A1 it) implements A1 {
  const factory E1.redir(A1 it) = E1;
}

test1() {
  const A1 a1 = const A1(0);
  expectIdentical(const A1.redir(a1), a1);
}

class A2 {
  final int foo;
  const A2(this.foo);
  const factory A2.redir(bool b) = E2.pick;
}

class B2 extends A2 {
  static const B2 element = const B2(0);
  const B2(super.foo);
}

class C2 extends A2 {
  static const C2 element = const C2(0);
  const C2(super.foo);
}

extension type const E2(A2 it) implements A2 {
  const E2.pick(bool b) : this(b ? B2.element : C2.element);
}

test2() {
  expectIdentical(const A2.redir(true), B2.element);
  expectIdentical(const A2.redir(false), C2.element);
}

expectIdentical(expected, actual) {
  if (!identical(expected, actual)) {
    throw "Expected '${expected}', actual '${actual}'.";
  }
}

main() {
  test1();
  test2();
}
