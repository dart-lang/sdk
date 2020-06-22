// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regresion test for bug discovered in frog handling super calls: the test case
// mixes generics, super calls, and purposely doesn't allocate the base type.
//
// Also is a regression test for https://github.com/dart-lang/sdk/issues/31973

import 'package:expect/expect.dart';

class C<T> {
  foo(T a) {}
}

class D<T> extends C<T> {
  foo(T a) {
    super.foo(a); // used to be resolved incorrectly and generate this.foo(a).
  }
}

class A {
  static int _value = -1;
  Function foo = (int x) => _value = x + 1;
}

class B extends A {
  void m(int x) {
    super.foo(x);
  }
}

main() {
  var d = new D();
  d.foo(null);

  var b = new B();
  b.m(41);
  Expect.equals(42, A._value);
}
