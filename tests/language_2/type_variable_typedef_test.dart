// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that rti dependency registration takes type variables within typedefs
// into account.

import 'package:expect/expect.dart';

typedef Foo<T>(T t);

class A<T> {
  m() => new B<Foo<T>>();
}

class B<T> {
  m(o) => o is T;
}

foo(int i) {}
bar(String s) {}

void main() {
  Expect.isTrue(new A<int>().m().m(foo));
  Expect.isFalse(new A<int>().m().m(bar));
  Expect.isFalse(new A<String>().m().m(foo));
  Expect.isTrue(new A<String>().m().m(bar));
  Expect.isFalse(new A<double>().m().m(foo));
  Expect.isFalse(new A<double>().m().m(bar));
}
