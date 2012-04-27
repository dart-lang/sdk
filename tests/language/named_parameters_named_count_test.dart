// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for named parameter called 'count'.


class TestClass {
  TestClass();

  method([count]) => count;

  static staticMethod([count]) => count;
}

globalMethod([count]) => count;


main() {
  var obj = new TestClass();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(0));
  Expect.equals(0, obj.method(count: 0));
  Expect.equals("", obj.method(""));
  Expect.equals("", obj.method(count: ""));

  Expect.equals(null, TestClass.staticMethod());
  Expect.equals(true, TestClass.staticMethod(true));
  Expect.equals(true, TestClass.staticMethod(count: true));
  Expect.equals(false, TestClass.staticMethod(false));
  Expect.equals(false, TestClass.staticMethod(count: false));

  Expect.equals(null, globalMethod());
  Expect.equals(true, globalMethod(true));
  Expect.equals(true, globalMethod(count: true));
  Expect.equals(false, globalMethod(false));
  Expect.equals(false, globalMethod(count: false));
}
