// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test empty stream.
import "package:expect/expect.dart";
import "dart:async";
import 'package:async_helper/async_helper.dart';

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

  Stream<int> s = const Stream<int>.empty(); // Is const constructor.
  Expect.isFalse(s is Stream<String>); // Respects type parameter.
  StreamSubscription<int> sub =
      s.listen(unreachable, onError: unreachable, onDone: ticker);
  Expect.isFalse(sub is StreamSubscription<String>); // Type parameter in sub.

  // Doesn't do callback in response to listen.
  Expect.equals(tick, 0);
  await flushMicrotasks();
  // Completes eventually.
  Expect.equals(tick, 1);

  // It's a broadcast stream - can listen twice.
  Expect.isTrue(s.isBroadcast);
  StreamSubscription<int> sub2 =
      s.listen(unreachable, onError: unreachable, onDone: unreachable);
  // respects pause.
  sub2.pause();
  await flushMicrotasks();
  // respects cancel.
  sub2.cancel();
  await flushMicrotasks();
  Expect.equals(tick, 1);
  // Still not complete.

  StreamSubscription<int> sub3 =
      s.listen(unreachable, onError: unreachable, onDone: ticker);
  // respects pause.
  sub3.pause();
  Expect.equals(tick, 1);
  await flushMicrotasks();
  // Doesn't complete while paused.
  Expect.equals(tick, 1);
  sub3.resume();
  await flushMicrotasks();
  // Now completed.
  Expect.equals(tick, 2);

  asyncEnd();
}

Future flushMicrotasks() => new Future.delayed(Duration.zero);
