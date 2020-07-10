// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this is a copy of the language test of the same name,
// we can remove this copy when we're running against those tests.
import "package:expect/expect.dart";

bar() sync* {
  int i = 1;
  int j = 1;
  while (true) {
    yield i;
    j = i + j;
    i = j - i;
  }
}

foo() sync* {
  yield* [1, 2, 3];
  yield null;
  // TODO(jmesserly): added cast here to work around:
  // https://codereview.chromium.org/1213503002/
  yield* bar() as Iterable;
}

main() async {
  Expect.listEquals([1, 2, 3, null, 1, 1, 2, 3, 5], foo().take(9).toList());
}
