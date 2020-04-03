// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

range(start, end) async* {
  for (int i = start; i < end; i++) {
    yield i;
  }
}

concat(a, b) async* {
  yield* a;
  yield* b;
}

test() async {
  Expect.listEquals(
      [1, 2, 3, 11, 12, 13], await concat(range(1, 4), range(11, 14)).toList());
}

main() {
  asyncStart();
  test().then((_) {
    asyncEnd();
  });
}
