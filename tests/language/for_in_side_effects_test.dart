// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to not see side effects of
// iterator calls made in a "for in".

import "package:expect/expect.dart";

var global = 42;
var array = [new A()];

class A {
  get iterator {
    global = 54;
    return this;
  }

  moveNext() => false;

  bar(a) {
    for (var a in this) {}
  }
}

main() {
  array[0].bar(global);
  Expect.equals(54, global);
}
