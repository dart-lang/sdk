// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream<int> foo1() async* {
  yield 1;
  var p = await new Future.value(10);
  yield p + 10;
}

Stream<int> foo2() async* {
  int i = 0;
  while (true) {
    await (new Future.delayed(new Duration(milliseconds: 0), () {}));
    if (i > 10) return;
    yield i;
    i++;
  }
}

Stream<int> foo3(p) async* {
  int i = 0;
  bool t = false;
  yield null;
  while (true) {
    i++;
    a:
    for (int i = 0; i < p; i++) {
      if (!t) {
        for (int j = 0; j < 3; j++) {
          yield -1;
          t = true;
          break a;
        }
      }
      await 4;
      yield i;
    }
  }
}

Completer<bool> finalized = new Completer<bool>();

Stream<int> foo4() async* {
  int i = 0;
  try {
    while (true) {
      yield i;
      i++;
    }
  } finally {
    // Canceling the stream-subscription should run the finalizer.
    finalized.complete(true);
  }
}

test() async {
  Expect.listEquals([1, 20], await (foo1().toList()));
  Expect.listEquals([0, 1, 2, 3], await (foo2().take(4).toList()));
  Expect.listEquals(
      [null, -1, 0, 1, 2, 3, 0, 1, 2, 3], await (foo3(4).take(10).toList()));
  Expect.listEquals(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], await (foo4().take(10).toList()));
  Expect.isTrue(await (finalized.future));
}

main() {
  asyncStart();
  test().then((_) {
    asyncEnd();
  });
}
