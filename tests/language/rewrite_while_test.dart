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

main() {
    Expect.equals(10, loop1(10));
    Expect.equals(10, loop2(10));
    Expect.equals(0, loop2(200));
}
