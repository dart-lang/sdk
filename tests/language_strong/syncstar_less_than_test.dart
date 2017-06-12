// Copyright (c) 2015, the Dart Team. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in
// the LICENSE file.

import "package:expect/expect.dart";

confuse(x) => [1, 'x', true, null, x].last;

Iterable<int> foo() sync* {
  var a = confuse(1);
  if (a < 10) {
    yield 2;
  }
}

main() {
  Expect.listEquals(foo().toList(), [2]);
}
