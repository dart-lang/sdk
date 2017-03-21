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
  Expect.equals(42, Class.fisk());
  Expect.equals(null, foo(Class.fisk()));

  // Verify references to a class literal are allowed.
  Class;
  var x = Class;
  foo(Class);
  Expect.isFalse(Class == null);

  // Verify that dereferencing a class literal is a runtime error.
  Expect.throws(() { Class(); }, (e) => e is NoSuchMethodError); //# 01: static type warning
  Expect.throws(() { Class[0]; }, (e) => e is NoSuchMethodError); //# 02: static type warning
  Expect.throws(() { var x = Class(); }, (e) => e is NoSuchMethodError); //# 03: static type warning
  Expect.throws(() { var x = Class[0]; }, (e) => e is NoSuchMethodError); //# 04: static type warning
  Expect.throws(() { var x = Class[0].field; }, (e) => e is NoSuchMethodError); //# 05: static type warning
  Expect.throws(() { var x = Class[0].method(); }, (e) => e is NoSuchMethodError); //# 06: static type warning
  Expect.throws(() { foo(Class()); }, (e) => e is NoSuchMethodError); //# 07: static type warning
  Expect.throws(() { foo(Class[0]); }, (e) => e is NoSuchMethodError); //# 08: static type warning
  Expect.throws(() { foo(Class[0].field); }, (e) => e is NoSuchMethodError); //# 09: static type warning
  Expect.throws(() { foo(Class[0].method()); }, (e) => e is NoSuchMethodError); //# 10: static type warning
  Expect.throws(() { Class[0] = 91; }, (e) => e is NoSuchMethodError); //# 11: static type warning
  Expect.throws(() { Class++; }, (e) => e is NoSuchMethodError); //# 12: static type warning
  Expect.throws(() { ++Class; }, (e) => e is NoSuchMethodError); //# 13: static type warning
  Expect.throws(() { Class[0] += 3; }, (e) => e is NoSuchMethodError); //# 14: static type warning
  Expect.throws(() { ++Class[0]; }, (e) => e is NoSuchMethodError); //# 15: static type warning
  Expect.throws(() { Class[0]++; }, (e) => e is NoSuchMethodError); //# 16: static type warning
  Expect.throws(() { Class.method(); }, (e) => e is NoSuchMethodError); //# 17: static type warning
  Expect.throws(() { Class.field; }, (e) => e is NoSuchMethodError); //# 18: static type warning
  Expect.throws(() { var x = Class.method(); }, (e) => e is NoSuchMethodError); //# 19: static type warning
  Expect.throws(() { var x = Class.field; }, (e) => e is NoSuchMethodError); //# 20: static type warning
  Expect.throws(() { foo(Class.method()); }, (e) => e is NoSuchMethodError); //# 21: static type warning
  Expect.throws(() { foo(Class.field); }, (e) => e is NoSuchMethodError); //# 22: static type warning
  Expect.throws(() { Class / 3; }, (e) => e is NoSuchMethodError); //# 23: static type warning
  Expect.throws(() { Class += 3; }, (e) => e is NoSuchMethodError); //# 24: static type warning

  // Verify that a class literal isn't a string literal.
  Expect.notEquals(Class, "Class");

  // Verify toString() works for class literals.
  Expect.isTrue((Class).toString() is String);
  var y = Class;
  Expect.isTrue(y.toString() is String);

  Expect.throws(() { Class.toString(); }, (e) => e is NoSuchMethodError); //# 25: static type warning
}
