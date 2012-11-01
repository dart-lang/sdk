// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test optimized charCodeAt and array access.

String one_byte = "hest";
String two_byte = "høns";

int testOneByteCharCodeAt(String x, int i) {
  int test() {
    return x.charCodeAt(i);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testTwoByteCharCodeAt(String x, int i) {
  int test() {
    return x.charCodeAt(i);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testConstantStringCharCodeAt(int i) {
  int test() {
    return "høns".charCodeAt(i);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


int testConstantIndexCharCodeAt(String x) {
  int test() {
    return x.charCodeAt(1);
  }
  for (int i = 0; i < 10000; i++) test();
  return test();
}


main() {
  Expect.equals(101, testOneByteCharCodeAt(one_byte, 1));
  Expect.equals(248, testTwoByteCharCodeAt(two_byte, 1));
  Expect.equals(248, testConstantStringCharCodeAt(1));
  Expect.equals(101, testConstantIndexCharCodeAt(one_byte));
}
