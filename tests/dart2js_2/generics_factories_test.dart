// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that factories are marked as needing rti.

import "package:expect/expect.dart";

class A<T> {
  foo(o) => o is T;
  factory A.c() => new B<T>();
  A();
}

class B<T> extends A<T> {}

class C {}

class D {}

main() {
  Expect.isTrue(new A<C>.c().foo(new C()));
  Expect.isFalse(new A<C>.c().foo(new D()));
}
