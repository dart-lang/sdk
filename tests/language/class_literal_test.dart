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
  if (false) {
    Class(); /// 02: compile-time error
    Class[0]; /// 05: compile-time error
    var x = Class(); /// 07: compile-time error
    var x = Class[0]; /// 10: compile-time error
    var x = Class[0].field; /// 11: compile-time error
    var x = Class[0].method(); /// 12: compile-time error
    foo(Class()); /// 14: compile-time error
    foo(Class[0]); /// 17: compile-time error
    foo(Class[0].field); /// 18: compile-time error
    foo(Class[0].method()); /// 19: compile-time error
    Class[0] = 91; /// 22: compile-time error
    Class++; /// 23: compile-time error
    ++Class; /// 24: compile-time error
    Class[0] += 3; /// 27: compile-time error
    ++Class[0]; /// 28: compile-time error
    Class[0]++; /// 29: compile-time error
  }
  Expect.equals(42, Class.fisk());
  Expect.equals(null, foo(Class.fisk()));
  
  // Verify references to a class literal are allowed.
  Class;
  var x = Class;
  foo(Class);
  Expect.isFalse(Class == null);

  // Verify that dereferencing a class literal is a runtime error.
  Expect.throws(() { Class.method(); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { Class.field; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var x = Class.method(); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { var x = Class.field; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(Class.method()); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { foo(Class.field); }, (e) => e is NoSuchMethodError);
  Expect.throws(() { Class / 3; }, (e) => e is NoSuchMethodError);
  Expect.throws(() { Class += 3; }, (e) => e is NoSuchMethodError);

  // Verify that a class literal is its runtimeType.
  var obj = new Class();
  Expect.identical(Class, obj.runtimeType);
  
  // Verify that a class literal isn't a string literal.
  Expect.notEquals(Class, "Class");
   
  // Verify toString() works for class literals.
  Expect.equals((Class).toString(), "Class");
  var y = Class;
  Expect.equals(y.toString(), "Class");
  
  Expect.throws(() { Class.toString(); }, (e) => e is NoSuchMethodError);
}
