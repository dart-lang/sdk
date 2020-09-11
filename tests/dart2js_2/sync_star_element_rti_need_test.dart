// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var x = [1, 2, 3];
  Expect.listEquals(x, nop(x).toList());
}

Iterable<T> nop<T>(Iterable<T> values) {
  Iterable<T> inner() sync* {
    yield* values;
    return;
  }

  return inner();
}
