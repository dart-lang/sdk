// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

void testSimpleScope() {
  {
    var a = "Test";
    int b = 1;
  }
  {
    var c;
    int d;
    Expect.isNull(c);
    Expect.isNull(d);
  }
}

void testShadowingScope() {
  var a = "Test";
  {
    var a;
    Expect.isNull(a);
    a = "a";
    Expect.equals(a, "a");
  }
  Expect.equals(a, "Test");
}

int testShadowingAfterUse() {
  var a = 1;
  {
    var b = 2;
    var c = a; // Use of 'a' prior to its shadow declaration below.
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Local variable 'a' can't be referenced before it is declared.
    var d = b + c;
    // Shadow declaration of 'a'.
    var a = 5;
    return d + a;
  }
}

main() {
  testSimpleScope();
  testShadowingScope();
  testShadowingAfterUse();
}
