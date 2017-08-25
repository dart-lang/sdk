// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for type checks involving callbacks and the type void.

import 'package:expect/expect.dart';

class A<T> {
  T x;

  foo(T x) {
  }

  T bar(T f()) {
    T tmp = f();
    return tmp;
  }

  gee(T f()) {
    x = bar(f);
  }

  Object xAsObject() => x;
}

void voidFun() => 499;
int intFun() => 42;

main() {
  A<void> a = new A<void>();
  a.foo(a.x);  //# 00: compile-time error
  a.bar(voidFun);
  Expect.equals(null, a.xAsObject());
  a.x = a.bar(voidFun);  //# 01: compile-time error
  a.gee(voidFun);
  Expect.equals(499, a.xAsObject());
  a.gee(intFun);
  Expect.equals(42, a.xAsObject());
}
