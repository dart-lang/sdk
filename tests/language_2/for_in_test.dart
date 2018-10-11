// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test for testing for in on a list literal.

main() {
  testSimple();
  testGenericSyntax1();
  testGenericSyntax2();
  testGenericSyntax3();
  testGenericSyntax4();
  testShadowLocal1();
  testShadowLocal2();
}

void testSimple() {
  var list = [1, 3, 5];
  var sum = 0;
  for (var i in list) {
    sum += i;
  }
  Expect.equals(9, sum);
}

void testGenericSyntax1() {
  List<List<String>> aCollection = [];
  for (List<String> strArrArr in aCollection) {}
}

void testGenericSyntax2() {
  List<List<String>> aCollection = [];
  List<String> strArrArr;
  for (strArrArr in aCollection) {}
}

void testGenericSyntax3() {
  List<List<List<String>>> aCollection = [];
  for (List<List<String>> strArrArr in aCollection) {}
}

void testGenericSyntax4() {
  List<List<List<String>>> aCollection = [];
  List<List<String>> strArrArr;
  for (strArrArr in aCollection) {}
}

void testShadowLocal1() {
  List<int> x = [1, 2, 3];
  var i = 0;
  for (var x in x) {
    Expect.equals(x, ++i);
  }
}

void testShadowLocal2() {
  Object x = [1, 2, 3];
  var i = 0;
  for (x in x) {
    Expect.equals(x, ++i);
  }
}
