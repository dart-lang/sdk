// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testOne();
  testTwo();
}

testOne() {
  // Dart2JS uses t[0-9]* to declare temporaries, so a local variable
  // with that pattern can conflict with them.
  var t0 = new List();
  // By using 'is' check, we make sure 't0.length' does not become
  // generate at use site.
  Expect.isTrue(t0.length is int);
  Expect.isTrue(t0 is List);
}

testTwo() {
  var x = new List();
  var x_0 = new List();
  {
    // This used to introduce x_0.
    var x = new Set();
    Expect.equals(0, x.length);
    Expect.isTrue(x.isEmpty);
  }
  Expect.isTrue(x is List);
  Expect.isTrue(x_0 is List);
}
