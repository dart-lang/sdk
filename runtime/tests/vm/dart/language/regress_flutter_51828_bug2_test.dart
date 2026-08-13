// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for the 2nd bug in
// https://github.com/flutter/flutter/issues/51828.
// Verifies that implicit cast of :result parameter of async_op
// doesn't affect subsequent uses.

import "package:expect/expect.dart";

dynamic bar() async => 42;
dynamic baz() async => 'hi';

use(x, y) {
  Expect.equals(42, x);
  Expect.equals(2, y.length);
}

main() async {
  int x = await bar();
  String y = await baz();
  use(x, y);
}
