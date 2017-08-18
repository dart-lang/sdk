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

  // Verify that dereferencing a class literal is a compile-time error.
  // TODO(jcollins-g): several tests here seem to depend on being in their
  // own namespace, but others do not.  More tests seem to also depend on
  // the complexities of Expect.throws() for other, unknown reasons to trigger
  // bugs in the VM as of this writing.
  //
  // Remove the legacy Expect.throws and namespaces around statements that don't
  // need it after a careful examination of each case.
  Expect.throws(() { Class(); }, (e) => e is NoSuchMethodError); //# 01: compile-time error
  Expect.throws(() { Class[0]; }, (e) => e is NoSuchMethodError); //# 02: compile-time error
  Expect.throws(() { var x = Class();}, (e) => e is NoSuchMethodError); //# 03: compile-time error
  Expect.throws(() { var x = Class[0]; }, (e) => e is NoSuchMethodError); //# 04: compile-time error
  Expect.throws(() { var x = Class[0].field; }, (e) => e is NoSuchMethodError); //# 05: compile-time error
  Expect.throws(() { var x = Class[0].method(); }, (e) => e is NoSuchMethodError); //# 06: compile-time error
  Expect.throws(() { foo(Class()); }, (e) => e is NoSuchMethodError); //# 07: compile-time error
  Expect.throws(() { foo(Class[0]); }, (e) => e is NoSuchMethodError); //# 08: compile-time error
  Expect.throws(() { foo(Class[0].field); }, (e) => e is NoSuchMethodError); //# 09: compile-time error
  Expect.throws(() { foo(Class[0].method()); }, (e) => e is NoSuchMethodError); //# 10: compile-time error
  Expect.throws(() { Class[0] = 91; }, (e) => e is NoSuchMethodError); //# 11: compile-time error
  Expect.throws(() { Class++; }, (e) => e is NoSuchMethodError); //# 12: compile-time error
  Expect.throws(() { ++Class; }, (e) => e is NoSuchMethodError); //# 13: compile-time error
  Expect.throws(() { Class[0] += 3; }, (e) => e is NoSuchMethodError); //# 14: compile-time error
  Expect.throws(() { ++Class[0]; }, (e) => e is NoSuchMethodError); //# 15: compile-time error
  Expect.throws(() { Class[0]++; }, (e) => e is NoSuchMethodError); //# 16: compile-time error
  Expect.throws(() { Class.method(); }, (e) => e is NoSuchMethodError); //# 17: compile-time error
  Expect.throws(() { Class.field; }, (e) => e is NoSuchMethodError); //# 18: compile-time error
  Expect.throws(() { var x = Class.method(); }, (e) => e is NoSuchMethodError); //# 19: compile-time error
  Expect.throws(() { var x = Class.field; }, (e) => e is NoSuchMethodError); //# 20: compile-time error
  Expect.throws(() { foo(Class.method()); }, (e) => e is NoSuchMethodError); //# 21: compile-time error
  Expect.throws(() { foo(Class.field); }, (e) => e is NoSuchMethodError); //# 22: compile-time error
  Expect.throws(() { Class / 3; }, (e) => e is NoSuchMethodError); //# 23: compile-time error
  Expect.throws(() { Class += 3; }, (e) => e is NoSuchMethodError); //# 24: compile-time error

  // Verify that a class literal isn't a string literal.
  Expect.notEquals(Class, "Class");

  // Verify toString() works for class literals.
  Expect.isTrue((Class).toString() is String);
  var y = Class;
  Expect.isTrue(y.toString() is String);

  Expect.throws(() { Class.toString(); }, (e) => e is NoSuchMethodError); //# 25: compile-time error
}
