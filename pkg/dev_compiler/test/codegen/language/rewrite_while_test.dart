// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";


baz() {}

loop1(x) {
    var n = 0;
    while (n < x) {
        n = n + 1;
    }
    return n;
}

loop2(x) {
    var n = 0;
    if (x < 100) {
        while (n < x) {
            n = n + 1;
        }
    }
    baz();
    return n;
}

loop3(x) {
    var n = 0;
    if (x < 100) {
        while (n < x) {
            n = n + 1;
            baz();
        }
    }
    baz();
    return n;
}

loop4(x) {
    var n = 0;
    if (x < 100) {
        while (n < x) {
            baz();
            n = n + 1;
        }
    }
    baz();
    return n;
}

f1(b) {
  while (b)
    return 1;

  return 2;
}

f2(b) {
  while (b) {
    return 1;
  }
  return 2;
}

main() {
    Expect.equals(0,  loop1(-10));
    Expect.equals(10, loop1(10));

    Expect.equals(0,  loop2(-10));
    Expect.equals(10, loop2(10));
    Expect.equals(0,  loop2(200));

    Expect.equals(0,  loop3(-10));
    Expect.equals(10, loop3(10));
    Expect.equals(0,  loop3(200));

    Expect.equals(0,  loop4(-10));
    Expect.equals(10, loop4(10));
    Expect.equals(0,  loop4(200));

    Expect.equals(1, f1(true));
    Expect.equals(2, f1(false));
    Expect.equals(1, f2(true));
    Expect.equals(2, f2(false));
}
