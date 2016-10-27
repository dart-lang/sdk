// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  Function fun;
  A(this.fun);
}

globalFunctionPositional(int a, [int b = 42]) => a + b;

globalFunctionNamed(int a, {int b: 42}) => a + b;

class Foo {
  int base;

  Foo(this.base);

  methodFunctionPositional(int a, [int b = 42]) => base + a + b;

  methodFunctionNamed(int a, {int b: 42}) => base + a + b;
}

main() {
  Expect.isTrue(new A(globalFunctionPositional).fun(1, 2) == 3);
  Expect.isTrue(new A(globalFunctionPositional).fun(1) == 43);
  Expect.isTrue(new A(globalFunctionNamed).fun(1, b: 2) == 3);
  Expect.isTrue(new A(globalFunctionNamed).fun(1) == 43);

  var foo = new Foo(100);
  Expect.isTrue(new A(foo.methodFunctionPositional).fun(1, 2) == 103);
  Expect.isTrue(new A(foo.methodFunctionPositional).fun(1) == 143);
  Expect.isTrue(new A(foo.methodFunctionNamed).fun(1, b: 2) == 103);
  Expect.isTrue(new A(foo.methodFunctionNamed).fun(1) == 143);
}
