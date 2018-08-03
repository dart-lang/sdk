// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the StreamView class.

import "package:expect/expect.dart";
import "dart:async";
import "package:async_helper/async_helper.dart";

main() {
  asyncStart();
  runTest().whenComplete(asyncEnd);
}

Future runTest() async {
  unreachable([a, b]) {
    throw "UNREACHABLE";
  }

  int tick = 0;
  ticker() {
    tick++;
  }

  asyncStart();

  // Is const constructor.
  Stream<int> s = const StreamView<int>(const Stream<int>.empty());

  Expect.isFalse(s is Stream<String>); // Respects type parameter.
  StreamSubscription<int> sub =
      s.listen(unreachable, onError: unreachable, onDone: ticker);
  Expect.isFalse(sub is StreamSubscription<String>); // Type parameter in sub.

  Stream iterableStream = new Stream.fromIterable([1, 2, 3]);
  Expect.listEquals([1, 2, 3], await iterableStream.toList());

  asyncEnd();
}

Future flushMicrotasks() => new Future.delayed(Duration.zero);
