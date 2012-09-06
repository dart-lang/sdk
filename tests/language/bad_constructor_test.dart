// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class A {
  // Constructor may not be static.
  static A();  /// 00: compile-time error

  // Factory may not be static.
  static factory A() { return null; }  /// 01: compile-time error

  // Constructor may not be abstract.
  abstract A();  /// 02: compile-time error

  // Factory may not be abstract
  abstract factory A() { return null; }  /// 03: compile-time error
}

main() {
  new A();
}
