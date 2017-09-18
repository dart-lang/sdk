// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing named parameters with 'false' passed as an
// argument.

class TestClass {
  TestClass();

  bool method([bool value]) => value;
  bool method2({bool value}) => value;

  static bool staticMethod([bool value]) => value;
  static bool staticMethod2({bool value}) => value;
}

bool globalMethod([bool value]) => value;
bool globalMethod2({bool value}) => value;

main() {
  var obj = new TestClass();

  Expect.equals(null, obj.method());
  Expect.equals(null, obj.method2());
  Expect.equals(true, obj.method(true));
  Expect.equals(true, obj.method2(value: true));
  Expect.equals(false, obj.method(false));
  Expect.equals(false, obj.method2(value: false));

  Expect.equals(null, TestClass.staticMethod());
  Expect.equals(null, TestClass.staticMethod2());
  Expect.equals(true, TestClass.staticMethod(true));
  Expect.equals(true, TestClass.staticMethod2(value: true));
  Expect.equals(false, TestClass.staticMethod(false));
  Expect.equals(false, TestClass.staticMethod2(value: false));

  Expect.equals(null, globalMethod());
  Expect.equals(null, globalMethod2());
  Expect.equals(true, globalMethod(true));
  Expect.equals(true, globalMethod2(value: true));
  Expect.equals(false, globalMethod(false));
  Expect.equals(false, globalMethod2(value: false));
}
