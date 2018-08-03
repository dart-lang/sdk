// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing named parameters with zero passed as an
// argument.

class TestClass {
  TestClass();

  num method([num value = 100]) => value;
  num method2({num value: 100}) => value;

  static num staticMethod([num value = 200]) => value;
  static num staticMethod2({num value: 200}) => value;
}

num globalMethod([num value = 300]) => value;
num globalMethod2({num value: 300}) => value;

main() {
  var obj = new TestClass();

  Expect.equals(100, obj.method());
  Expect.equals(100, obj.method2());
  Expect.equals(7, obj.method(7));
  Expect.equals(7, obj.method2(value: 7));
  Expect.equals(0, obj.method(0));
  Expect.equals(0, obj.method2(value: 0));

  Expect.equals(200, TestClass.staticMethod());
  Expect.equals(200, TestClass.staticMethod2());
  Expect.equals(7, TestClass.staticMethod(7));
  Expect.equals(7, TestClass.staticMethod2(value: 7));
  Expect.equals(0, TestClass.staticMethod(0));
  Expect.equals(0, TestClass.staticMethod2(value: 0));

  Expect.equals(300, globalMethod());
  Expect.equals(300, globalMethod2());
  Expect.equals(7, globalMethod(7));
  Expect.equals(7, globalMethod2(value: 7));
  Expect.equals(0, globalMethod(0));
  Expect.equals(0, globalMethod2(value: 0));
}
