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
  Expect.throwsNoSuchMethodError(() { Class(); }); //# 01: compile-time error
  Expect.throwsNoSuchMethodError(() { Class[0]; }); //# 02: compile-time error
  Expect.throwsNoSuchMethodError(() { var x = Class();}); //# 03: compile-time error
  Expect.throwsNoSuchMethodError(() { var x = Class[0]; }); //# 04: compile-time error
  Expect.throwsNoSuchMethodError(() { var x = Class[0].field; }); //# 05: compile-time error
  Expect.throwsNoSuchMethodError(() { var x = Class[0].method(); }); //# 06: compile-time error
  Expect.throwsNoSuchMethodError(() { foo(Class()); }); //# 07: compile-time error
  Expect.throwsNoSuchMethodError(() { foo(Class[0]); }); //# 08: compile-time error
  Expect.throwsNoSuchMethodError(() { foo(Class[0].field); }); //# 09: compile-time error
  Expect.throwsNoSuchMethodError(() { foo(Class[0].method()); }); //# 10: compile-time error
  Expect.throwsNoSuchMethodError(() { Class[0] = 91; }); //# 11: compile-time error
  Expect.throwsNoSuchMethodError(() { Class++; }); //# 12: compile-time error
  Expect.throwsNoSuchMethodError(() { ++Class; }); //# 13: compile-time error
  Expect.throwsNoSuchMethodError(() { Class[0] += 3; }); //# 14: compile-time error
  Expect.throwsNoSuchMethodError(() { ++Class[0]; }); //# 15: compile-time error
  Expect.throwsNoSuchMethodError(() { Class[0]++; }); //# 16: compile-time error
  Expect.throwsNoSuchMethodError(() { Class.method(); }); //# 17: compile-time error
  Expect.throwsNoSuchMethodError(() { Class.field; }); //# 18: compile-time error
  Expect.throwsNoSuchMethodError(() { var x = Class.method(); }); //# 19: compile-time error
  Expect.throwsNoSuchMethodError(() { var x = Class.field; }); //# 20: compile-time error
  Expect.throwsNoSuchMethodError(() { foo(Class.method()); }); //# 21: compile-time error
  Expect.throwsNoSuchMethodError(() { foo(Class.field); }); //# 22: compile-time error
  Expect.throwsNoSuchMethodError(() { Class / 3; }); //# 23: compile-time error
  Expect.throwsNoSuchMethodError(() { Class += 3; }); //# 24: compile-time error

  // Verify that a class literal isn't a string literal.
  Expect.notEquals(Class, "Class");

  // Verify toString() works for class literals.
  Expect.isTrue((Class).toString() is String);
  var y = Class;
  Expect.isTrue(y.toString() is String);

  Expect.throwsNoSuchMethodError(() => Class.toString()); //# 25: compile-time error
}
