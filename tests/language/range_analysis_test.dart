// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check that range analysis does not enter infinite loop trying to propagate
// ranges through dependant phis.
bar() {
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    for (var j = i - 1; j >= 0; j--) {
      for (var k = j; k < i; k++) {
        sum += (i + j + k);
      }
    }
  }
  return sum;
}

test1() {
  for (var i = 0; i < 1000; i++) bar();
}

// Check that range analysis does not erroneously remove overflow check.
test2() {
  var width = 1073741823;
  print(foo(width - 5000, width - 1));
  print(foo(width - 5000, width));
}

foo(n, w) {
  var x = 0;
  for (var i = n; i <= w; i++) {
    Expect.isTrue(i > 0);
    x = i;
  }
  return x;
}

main() {
  test1();
  test2();
}