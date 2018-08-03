// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_expression_test;

main() {
  var f = (int m, int n) => print('${m++}$n');
  var a1 = 3;
  var a2 = 7;

  f(a1, a2);

  int foo(int f1, String f2) {
    print('$f1, $f2');
    a1++;
    return a1;
  }

  var m = foo(1, 'test');
  print(m);
  print(a1);

  int bar(int i) {
    if (i < 0 || i == 0) return 0;
    return bar(--i);
  }

  print(bar(5));
}
