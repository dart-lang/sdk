// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that using a field or a global variable for a for/in variable
// works.

import "package:expect/expect.dart";

Set<int> set = new Set.from([1, 2]);
var x;

class A {
  var field;
  test() {
    int count = 0;
    for (field in set) {
      count += field;
    }
    Expect.equals(3, count);

    count = 0;
    for (x in set) {
      count += x;
    }
    Expect.equals(3, count);
  }
}

void main() {
  new A().test();
}
