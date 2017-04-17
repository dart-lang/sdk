// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  yield* bar();
}

main() async {
  Expect.listEquals([1, 2, 3, null, 1, 1, 2, 3, 5], foo().take(9).toList());
}
