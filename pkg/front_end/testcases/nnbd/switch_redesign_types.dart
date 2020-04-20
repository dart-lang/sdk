// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks the constraints for types of the case expressions.  The rules
// can be found at the following link:
// https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md#errors-and-warnings

class A {
  final int foo;
  const A(this.foo);
}

class B extends A {
  const B(int foo) : super(foo);
}

class C extends B {
  const C(int foo) : super(foo);
}

class D extends B {
  const D(int foo) : super(foo);

  bool operator ==(dynamic other) => identical(this, other);
}

bar(B b) {
  const dynamic x = const D(123);
  switch (b) {
    case const B(42):
      break;
    case const C(42):
      break;
    case const A(42): // Error: not a subtype of B.
      break;
    case const D(42): // Error: D has custom operator ==.
      break;
    case x: // Error: D has custom operator ==.
      break;
    default:
  }
}

main() {}
