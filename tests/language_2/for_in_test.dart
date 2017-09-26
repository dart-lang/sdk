// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test for testing for in on a list literal.

class ForInTest {
  static testMain() {
    testSimple();
    testGenericSyntax1();
    testGenericSyntax2();
    testGenericSyntax3();
    testGenericSyntax4();
  }

  static void testSimple() {
    var list = [1, 3, 5];
    var sum = 0;
    for (var i in list) {
      sum += i;
    }
    Expect.equals(9, sum);
  }

  static void testGenericSyntax1() {
    List<List<String>> aCollection = [];
    for (List<String> strArrArr in aCollection) {}
  }

  static void testGenericSyntax2() {
    List<List<String>> aCollection = [];
    List<String> strArrArr;
    for (strArrArr in aCollection) {}
  }

  static void testGenericSyntax3() {
    List<List<List<String>>> aCollection = [];
    for (List<List<String>> strArrArr in aCollection) {}
  }

  static void testGenericSyntax4() {
    List<List<List<String>>> aCollection = [];
    List<List<String>> strArrArr;
    for (strArrArr in aCollection) {}
  }
}

main() {
  ForInTest.testMain();
}
