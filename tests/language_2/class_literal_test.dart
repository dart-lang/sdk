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
  foo(Class);
  Expect.isFalse(Class == null);
  dynamic x = Class;

  // Verify that dereferencing a class literal is a runtime error.
  Expect.throws(() { x(); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x[0]; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var y = x[0]; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var y = x[0].field; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var y = x[0].method(); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(x()); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(x[0]); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(x[0].field); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(x[0].method()); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x[0] = 91; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x++; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { ++x; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x[0] += 3; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { ++x[0]; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x[0]++; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x.method(); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x.field; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var y = x.method(); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var y = x.field; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(x.method()); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(x.field); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x / 3; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { x += 3; }, (e) => e is NoSuchMethodError);

  // Verify that a class literal isn't a string literal.
  Expect.notEquals(Class, "Class");

  // Verify toString() works for class literals.
  Expect.isTrue((Class).toString() is String);
  Expect.isTrue(x.toString() is String);
}
