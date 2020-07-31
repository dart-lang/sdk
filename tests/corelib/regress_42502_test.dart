// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/42502.
// Requirements=nnbd-strong

import "package:expect/expect.dart";

void main() {
  List<int> x = [];
  Expect.throws(() {
    x.length = x.length + 1;
  });
  Expect.equals(0, x.length);
  x.add(222);
  Expect.equals(1, x.length);
  Expect.throws(() {
    x.length = 2;
  });
  Expect.equals(1, x.length);
  Expect.throws(() {
    x.length = x.length + 1;
  });
  Expect.equals(1, x.length);
  Expect.equals(222, x[0]);
}
