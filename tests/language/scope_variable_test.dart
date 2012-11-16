// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ScopeVariableTest {

  static void testSimpleScope() {
    {
      var a = "Test";
      int b = 1;
    }
    {
      var c;
      int d;
      Expect.equals(true, c == null);
      Expect.equals(true, d == null);
    }
  }

  static void testShadowingScope() {
    var a = "Test";
    {
      var a;
      Expect.equals(true, a == null);
      a = "a";
      Expect.equals(true, a == "a");
    }
    Expect.equals(true, a == "Test");
  }

  static void testMain() {
    testSimpleScope();
    testShadowingScope();
  }
}

main() {
  ScopeVariableTest.testMain();
}
