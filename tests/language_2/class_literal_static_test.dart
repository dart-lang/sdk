// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test class literal expressions.

class Class {
  static fisk() => 42;
}

foo(x) {}

main() {
  // Verify that dereferencing a class literal is a compile-time error.
  Class(); //# 01: compile-time error
  Class[0]; //# 02: compile-time error
  var x = Class(); //# 03: compile-time error
  var y = Class[0]; //# 04: compile-time error
  var z = Class[0].field; //# 05: compile-time error
  var w = Class[0].method(); //# 06: compile-time error
  foo(Class()); //# 07: compile-time error
  foo(Class[0]); //# 08: compile-time error
  foo(Class[0].field); //# 09: compile-time error
  foo(Class[0].method()); //# 10: compile-time error
  Class[0] = 91; //# 11: compile-time error
  Class++; //# 12: compile-time error
  ++Class; //# 13: compile-time error
  Class[0] += 3; //# 14: compile-time error
  ++Class[0]; //# 15: compile-time error
  Class[0]++; //# 16: compile-time error
  Class.method(); //# 17: compile-time error
  Class.field; //# 18: compile-time error
  var p = Class.method(); //# 19: compile-time error
  var q = Class.field; //# 20: compile-time error
  foo(Class.method()); //# 21: compile-time error
  foo(Class.field); //# 22: compile-time error
  Class / 3; //# 23: compile-time error
  Class += 3; //# 24: compile-time error
  Class.toString(); //# 25: compile-time error
}
