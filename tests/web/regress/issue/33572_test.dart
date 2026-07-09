// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 32853.

import "package:expect/expect.dart";

class A {
  final x = null;
  final y;
  const A(this.y);
}

main() {
  var a1 = new A(1);
  var a2 = const A(2);
  test(a1, null, 1);
  test(a2, null, 2);
}

@pragma('dart2js:noInline')
test(a, expectedX, expectedY) {
  Expect.equals(expectedX, a.x);
  Expect.equals(expectedY, a.y);
}
