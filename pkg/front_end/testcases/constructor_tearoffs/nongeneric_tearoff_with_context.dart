// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.foo1() {}
  A.foo2(int x) {}
  A() {}
  factory A.bar1() => new A();
}

A Function() test1() => A.foo1; // Ok.
A Function() test2() => A.foo2; // Error.
A Function() test3() => A.new; // Ok.
A Function(int) test4() => A.new; // Error.
A Function() test5() => A.bar1; // Ok.
A Function(int) test6() => A.bar1; // Error.

main() {}
