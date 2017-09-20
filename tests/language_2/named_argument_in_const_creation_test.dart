// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final x;
  final y;
  const A(a, {b})
      : x = a,
        y = b;
  static const test = const A(1, b: 2);
}

main() {
  A a = A.test;
  Expect.equals(1, a.x);
  Expect.equals(2, a.y);
}
