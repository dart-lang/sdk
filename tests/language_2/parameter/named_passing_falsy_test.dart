// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing named parameters with various values that might
// be implemented as 'falsy' values in a JavaScript implementation.

class TestClass {
  TestClass();

  method([value = 100]) => value;
  method2({value: 100}) => value;

  static staticMethod([value = 200]) => value;
  static staticMethod2({value: 200}) => value;
}

globalMethod([value = 300]) => value;
globalMethod2({value: 300}) => value;

const testValues = const [0, 0.0, '', false, null];

testFunction(f, f2) {
  Expect.isTrue(f() >= 100);
  for (var v in testValues) {
    Expect.equals(v, f(v));
    Expect.equals(v, f2(value: v));
  }
}

main() {
  var obj = new TestClass();

  Expect.equals(100, obj.method());
  Expect.equals(100, obj.method2());
  Expect.equals(200, TestClass.staticMethod());
  Expect.equals(200, TestClass.staticMethod2());
  Expect.equals(300, globalMethod());
  Expect.equals(300, globalMethod2());

  for (var v in testValues) {
    Expect.equals(v, obj.method(v));
    Expect.equals(v, obj.method2(value: v));
    Expect.equals(v, TestClass.staticMethod(v));
    Expect.equals(v, TestClass.staticMethod2(value: v));
    Expect.equals(v, globalMethod(v));
    Expect.equals(v, globalMethod2(value: v));
  }

  // Test via indirect call.
  testFunction(obj.method, obj.method2);
  testFunction(TestClass.staticMethod, TestClass.staticMethod2);
  testFunction(globalMethod, globalMethod2);
}
