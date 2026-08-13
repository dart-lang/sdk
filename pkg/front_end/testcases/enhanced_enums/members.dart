// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {
  one(1),
  two(2);

  final int foo;
  final int bar = 42;

  static E staticFoo = new E.f();

  const E(this.foo);

  factory E.f() => E.one;

  int method(int value) => value + 10;

  String staticMethod(double d, bool b) => "$d$b";
}

enum E2<X> {
  one<num>(1),
  two("2");

  final X foo;
  final X? bar = null;

  static var staticFoo = () => new E2.f();

  const E2(this.foo);

  factory E2.f() => throw 42;

  int method(int value) => value + 10;

  String staticMethod(double d, X x) => "$d$x";
}

main() {}
