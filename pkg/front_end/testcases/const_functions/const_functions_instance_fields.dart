// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests instance field usage with const functions.

import "package:expect/expect.dart";

class A {
  final int y;

  const A(this.y);
}

const var1 = fn();
int fn() => const A(1).y;

const var2 = fn2();
int fn2() {
  var x = const A(1);
  return x.y;
}

const var3 = const A(1).y;

class B extends A {
  const B(int x) : super(x);
}

const var4 = fn4();
int fn4() => const B(1).y;

class C extends A {
  @override
  final int y = 2;

  const C() : super(100);
}

const var5 = fn5();
int fn5() => const C().y;

void main() {
  Expect.equals(var1, 1);
  Expect.equals(var2, 1);
  Expect.equals(var3, 1);
  Expect.equals(var4, 1);
  Expect.equals(var5, 2);
}
