// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that phi type computation in the Dart2Js compiler does the
// correct thing.

import "package:expect/expect.dart";

bar() => 'foo';

main() {
  Expect.throws(foo1);
  Expect.throws(foo2);
}

foo1() {
  var a = bar();
  for (;; a = 1 + a) {
    if (a != 'foo') return;
  }
}

foo2() {
  var a = bar();
  for (;; a = 1 + a) {
    if (a != 'foo') break;
  }
}
