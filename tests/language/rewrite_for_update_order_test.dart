// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var counter = 0;
var global = 0;

test() {
    ++counter;
    return counter <= 2;
}

first() {
    global = global + 1;
}
second() {
    global = global * 2;
}

foo() {
    while (test()) {
        first();
        second();
    }
}

main() {
    foo();
    Expect.equals(6, global);
}
