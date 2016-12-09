// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  var things = [0, double.INFINITY, double.NEGATIVE_INFINITY];
  var first = things[1];
  var second = things[2];
  Expect.isFalse(first is int);
  Expect.isFalse(second is int);
  Expect.isTrue(first is double);
  Expect.isTrue(second is double);
}
