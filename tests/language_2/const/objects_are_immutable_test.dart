// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that const objects (including literals) are immutable.

import "package:expect/expect.dart";

class A {
  const A(this.x, this.y);
  final num x, y;
}

main() {
  dynamic list = const [1, 2];
  Expect.throws(() => list[0] = 3);
  Expect.equals(1, list[0]);

  dynamic m = const {'foo': 499};
  Expect.throws(() => m['foo'] = 42);
  Expect.equals(499, m['foo']);

  dynamic a1 = const A(1, 2);
  Expect.throws(() => a1.x = 499);
  Expect.equals(1, a1.x);

  dynamic a2 = const A(1, 2);
  Expect.throws(() => a2.x = 499);
  Expect.equals(1, a2.x);
}
