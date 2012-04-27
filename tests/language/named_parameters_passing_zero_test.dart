// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing named parameters with zero passed as an
// argument.


class TestClass {
  TestClass();

  num method([num value = 100]) => value;

  static num staticMethod([num value = 200]) => value;
}

num globalMethod([num value = 300]) => value;


main() {
  var obj = new TestClass();

  Expect.equals(100, obj.method());
  Expect.equals(7, obj.method(7));
  Expect.equals(7, obj.method(value: 7));
  Expect.equals(0, obj.method(0));
  Expect.equals(0, obj.method(value: 0));

  Expect.equals(200, TestClass.staticMethod());
  Expect.equals(7, TestClass.staticMethod(7));
  Expect.equals(7, TestClass.staticMethod(value: 7));
  Expect.equals(0, TestClass.staticMethod(0));
  Expect.equals(0, TestClass.staticMethod(value: 0));

  Expect.equals(300, globalMethod());
  Expect.equals(7, globalMethod(7));
  Expect.equals(7, globalMethod(value: 7));
  Expect.equals(0, globalMethod(0));
  Expect.equals(0, globalMethod(value: 0));
}
