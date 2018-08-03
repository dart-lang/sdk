// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to see aborting closure
// bodies as aborting their enclosing element.

import "package:expect/expect.dart";

main() {
  var c = () {
    throw 42;
  };
  () {
    // dart2js would not seen this initialization and therefore think
    // that the argument passed to a is a list of nulls.
    var a = [42];
    foo(a);
  }();
}

foo(arg) {
  Expect.isTrue(arg[0] == 42);
}
