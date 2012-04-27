// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that static members cannot be overridden (static type warning only).

m() {}

class Super {
  Super() {}
  // No error from hiding.
  static m() {}

  static var i;

  instanceMethod() {}
}

class Sub extends Super {
  Sub() : super();
  static m() {} /// 01: static type warning

  static var i; /// 02: static type warning

  static instanceMethod() {} /// 03: compile-time error

  static i() {} /// 04: static type warning

  static var instanceMethod; /// 05: compile-time error

  foo() {}
}

main() {
  new Sub().foo();
}
