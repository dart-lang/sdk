// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:math' as math;

class Random {}

typedef F(Random r);

main() {
  f(Random r) {}
  g(math.Random r) {}
  Expect.isTrue(f is F);
  Expect.isFalse(g is F);
}
