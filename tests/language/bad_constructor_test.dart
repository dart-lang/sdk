// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--constructor_name_check

class A {
  // Constructor may not be static.
  static A();  /// 00: compile-time error

  // Factory may not be static.
  static factory A() { return null; }  /// 01: compile-time error

  // Named constructor may not conflict with names of methods and fields.
  var m;
  A.m() { m = 0; }  /// 04: compile-time error

  set q(var value) { m = q; }
  A.q();   /// 05: compile-time error

  A.foo() : m = 0;  /// 06: compile-time error
  int foo(int a, int b) => a + b * m;
}

main() {
  new A();
}
