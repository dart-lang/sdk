// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks correctness of super tearoff invocation order across complex mixin
// hierarchies.

import "package:expect/expect.dart";

var superTearoffCallOrder = <String>[];

class C extends Super1 with M1, M2 {}

mixin M1 on Super2 {}

mixin M2 on Super1 {}

class Super1 extends Super2 {
  paint() {
    superTearoffCallOrder.add('Super1');
    return super.paint;
  }
}

class Super2 {
  paint() {
    superTearoffCallOrder.add('Super2');
    return this.paint;
  }
}

main() {
  var tearoff = C().paint();
  tearoff();
  Expect.listEquals(['Super1', 'Super2'], superTearoffCallOrder);
}
