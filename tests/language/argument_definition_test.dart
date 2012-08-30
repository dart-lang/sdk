// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing argument definition test.

int test(int a, [int b, int c]) {
  int result = 0;
  ?b;
  ?result;  /// 01: compile-time error
  if (?a) {
    result += 100;
  }
  if (?b) {
    result += 20;
  }
  if (?c) {
    var b; ?b;  /// 02: compile-time error
    result += 3;
  }
  return result;
}

closure_test(int a, [int b, int c]) {
  var x = 0;
  return () {
    int result = 0;
    ?b;
    ?result;  /// 03: compile-time error
    ?x;  /// 04: compile-time error
    if (?a) {
      result += 100;
    }
    if (?b) {
      result += 20;
    }
    if (?c) {
      var b; ?b;  /// 05: compile-time error
      result += 3;
    }
    return result;
  };
}

main() {
  // Use a loop to test optimized version as well.
  for (int i = 0; i < 1000; i++) {
    Expect.equals(100, test(1));
    Expect.equals(120, test(1, 2));
    Expect.equals(123, test(1, 2, 3));
    Expect.equals(103, test(1, c:3));

    Expect.equals(100, closure_test(1)());
    Expect.equals(120, closure_test(1, 2)());
    Expect.equals(123, closure_test(1, 2, 3)());
    Expect.equals(103, closure_test(1, c:3)());
  }
}
