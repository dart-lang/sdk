// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing named parameters with 'null' passed as an
// argument.

class TestClass {
  TestClass();

  num method([value = 100]) => value;
  num method2({value: 100}) => value;

  static num staticMethod([value = 200]) => value;
  static num staticMethod2({value: 200}) => value;
}

num globalMethod([value = 300]) => value;
num globalMethod2({value: 300}) => value;

main() {
  var obj = new TestClass();

  Expect.equals(100, obj.method());
  Expect.equals(100, obj.method2());
  Expect.equals(50, obj.method(50));
  Expect.equals(50, obj.method2(value: 50));
  Expect.equals(null, obj.method(null));
  Expect.equals(null, obj.method2(value: null));

  Expect.equals(200, TestClass.staticMethod());
  Expect.equals(200, TestClass.staticMethod2());
  Expect.equals(50, TestClass.staticMethod(50));
  Expect.equals(50, TestClass.staticMethod2(value: 50));
  Expect.equals(null, TestClass.staticMethod(null));
  Expect.equals(null, TestClass.staticMethod2(value: null));

  Expect.equals(300, globalMethod());
  Expect.equals(300, globalMethod2());
  Expect.equals(50, globalMethod(50));
  Expect.equals(50, globalMethod2(value: 50));
  Expect.equals(null, globalMethod(null));
  Expect.equals(null, globalMethod2(value: null));
}
