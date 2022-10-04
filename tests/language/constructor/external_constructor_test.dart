// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for external constructors.

import "package:expect/expect.dart";

class A {
  final int field;

  const A(this.field);
  external const A.foo(dynamic arg);
}

class B extends A {
  const B(int abc) : super(abc);
  B.foo(dynamic arg) : super.foo(arg);
}

void main() {
  Expect.throws(() {
    A.foo(42);
  }, (e) => e is NoSuchMethodError);
  Expect.throws(() {
    B.foo(42);
  }, (e) => e is NoSuchMethodError);
}
