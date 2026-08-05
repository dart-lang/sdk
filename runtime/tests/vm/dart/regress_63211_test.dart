// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that 'is Foo' is handled correctly when constant Foo is
// hidden by Redefinition.
// Regression test for https://github.com/dart-lang/sdk/issues/63211.

// VMOptions=--optimization-counter-threshold=100 --no-background-compilation

import 'package:expect/expect.dart';

class Foo1 {
  Foo1(this.x);
  int x;

  @pragma('vm:prefer-inline')
  @override
  bool operator ==(Object other) {
    return other is Foo1 && x == other.x;
  }
}

final v1 = Foo1(42);
const c1 = Foo1;

void test1() {
  Expect.isFalse(v1 == c1);
}

class Foo2 {
  @pragma('vm:prefer-inline')
  @override
  bool operator ==(Object other) {
    return other is Foo2;
  }
}

final v2 = Foo2();
const c2 = Foo2;

void test2() {
  Expect.isFalse(v2 == c2);
}

void main() {
  for (int i = 0; i < 200; ++i) {
    test1();
    test2();
  }
}
