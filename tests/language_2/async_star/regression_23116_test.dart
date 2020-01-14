// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://code.google.com/p/dart/issues/detail?id=23116

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';

Stream<int> foo(Completer completer, Future future) async* {
  completer.complete(100);
  int x = await future;
  Expect.equals(42, x);
}

test() async {
  Completer completer1 = new Completer();
  Completer completer2 = new Completer();
  StreamSubscription s = foo(completer1, completer2.future).listen((v) => null);
  await completer1.future;
  // At this moment foo is waiting on the given future.
  s.pause();
  // Ensure that execution of foo is not resumed - the future is not completed
  // yet.
  s.resume();
  completer2.complete(42);
}

main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
