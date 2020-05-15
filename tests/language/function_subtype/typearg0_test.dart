// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping with type variables in factory constructors.

import 'package:expect/expect.dart';

typedef void Foo();

class A<T> {
  bool foo(a) => a is T;
}

void bar1() {}
void bar2(i) {}

void main() {
  void bar3() {}
  void bar4(i) {}

  Expect.isTrue(new A<Foo>().foo(bar1));
  Expect.isFalse(new A<Foo>().foo(bar2));
  Expect.isTrue(new A<Foo>().foo(bar3));
  Expect.isFalse(new A<Foo>().foo(bar4));
  Expect.isTrue(new A<Foo>().foo(() {}));
  Expect.isFalse(new A<Foo>().foo((i) {}));
}
