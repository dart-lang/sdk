// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test parsing and resolution of argument definition test.

int test(int a, [int b = 2, int c = 3]) {
  int result = 0;
  print(?b);
  print(?result);  /// 01: compile-time error
  print(?a);
  print(?b);
  print(?c);
  {
    var b;
    ?b;  /// 02: compile-time error
  }
  print((!?a?!?b:!?c) == (?a??b:?c));
  print(!?a?!?b:!?c == ?a??b:?c);
}

closure_test(int a, [int b = 2, int c = 3]) {
  var x = 0;
  return () {
    int result = 0;
    print(?b);
    print(?result);  /// 03: compile-time error
    print(?x);  /// 04: compile-time error
    print(?a);
    print(?b);
    print(?c);
    {
      var b;
      ?b;  /// 05: compile-time error
    }
    print((!?a?!?b:!?c) == (?a??b:?c));
    print(!?a?!?b:!?c == ?a??b:?c);
  };
}

main() {
  test(1);
  test(1, 2);
  test(1, 2, 3);
  test(1, c:3);

  closure_test(1)();
  closure_test(1, 2)();
  closure_test(1, 2, 3)();
  closure_test(1, c:3)();
}
