// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that classes cannot be used as expressions.

class Class {
  static fisk() => 42;
}

foo(x) {}

main() {
  if (false) {
    Class; /// 01: compile-time error
    Class(); /// 02: compile-time error
    Class.method(); /// 03: static type warning
    Class.field; /// 04: static type warning
    Class[0]; /// 05: compile-time error
    var x = Class; /// 06: compile-time error
    var x = Class(); /// 07: compile-time error
    var x = Class.method(); /// 08: static type warning
    var x = Class.field; /// 09: static type warning
    var x = Class[0]; /// 10: compile-time error
    var x = Class[0].field; /// 11: compile-time error
    var x = Class[0].method(); /// 12: compile-time error
    foo(Class); /// 13: compile-time error
    foo(Class()); /// 14: compile-time error
    foo(Class.method()); /// 15: static type warning
    foo(Class.field); /// 16: static type warning
    foo(Class[0]); /// 17: compile-time error
    foo(Class[0].field); /// 18: compile-time error
    foo(Class[0].method()); /// 19: compile-time error
    Class === null; /// 20: compile-time error
    null === Class; /// 21: compile-time error
    Class[0] = 91; /// 22: compile-time error
    Class++; /// 23: compile-time error
    ++Class; /// 24: compile-time error
    Class / 3; /// 25: compile-time error
    Class += 3; /// 26: compile-time error
    Class[0] += 3; /// 27: compile-time error
    ++Class[0]; /// 28: compile-time error
    Class[0]++; /// 29: compile-time error
  }
  Expect.equals(42, Class.fisk());
  Expect.equals(null, foo(Class.fisk()));
}
