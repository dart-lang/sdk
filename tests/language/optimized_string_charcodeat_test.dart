// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test optimized CodeUnitAt and array access.

import "package:expect/expect.dart";


String one_byte = "hest";
String two_byte = "høns";

int testOneByteCodeUnitAt(String x, int j) {
  int test() {
    return x.codeUnitAt(j);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testTwoByteCodeUnitAt(String x, int j) {
  int test() {
    return x.codeUnitAt(j);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testConstantStringCodeUnitAt(int j) {
  int test() {
    return "høns".codeUnitAt(j);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testConstantIndexCodeUnitAt(String x) {
  int test() {
    return x.codeUnitAt(1);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testOneByteCodeUnitAtInLoop(var x) {
  var result = 0;
  for (int i = 0; i < x.length; i++) {
    result += x.codeUnitAt(i);
  }
  return result;
}


int testTwoByteCodeUnitAtInLoop(var x) {
  var result = 0;
  for (int i = 0; i < x.length; i++) {
    result += x.codeUnitAt(i);
  }
  return result;
}


main() {
  for (int j = 0; j < 10; j++) {
    Expect.equals(101, testOneByteCodeUnitAt(one_byte, 1));
    Expect.equals(248, testTwoByteCodeUnitAt(two_byte, 1));
    Expect.equals(248, testConstantStringCodeUnitAt(1));
    Expect.equals(101, testConstantIndexCodeUnitAt(one_byte));
  }
  for (int j = 0; j < 2000; j++) {
    Expect.equals(436, testOneByteCodeUnitAtInLoop(one_byte));
    Expect.equals(577, testTwoByteCodeUnitAtInLoop(two_byte));
  }
  Expect.throws(() => testOneByteCodeUnitAtInLoop(123));
  Expect.throws(() => testTwoByteCodeUnitAtInLoop(123));
}
