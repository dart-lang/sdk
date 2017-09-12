// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that async functions don't zone-register their callbacks for each
// await. Async functions should register their callback once in the beginning
// and then reuse it for all awaits in their body.
// This has two advantages: it is faster, when there are several awaits (on
// the Future class from dart:async), and it avoids zone-nesting when tracing
// stacktraces.
// See http://dartbug.com/23394 for more information.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

gee(i) async {
  return await i;
}

bar() async* {
  var i = 0;
  while (true) yield await gee(i++);
}

awaitForTest() async {
  var sum = 0;
  await for (var x in bar().take(100)) {
    sum += x;
  }
  Expect.equals(4950, sum);
}

awaitTest() async {
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  await null;
  return await 499;
}

runTests() async {
  await awaitTest();
  await awaitForTest();
}

var depth = 0;

var depthIncreases = 0;

increaseDepth() {
  depthIncreases++;
  depth++;
  // The async/await code should not register callbacks recursively in the
  // then-calls. As such the depth should never grow too much. We don't want
  // to commit to a specific value, since implementations still have some
  // room in how async/await is implemented, but 20 should be safe.
  Expect.isTrue(depth < 20);
}

dynamic Function() registerCallback(
    Zone self, ZoneDelegate parent, Zone zone, f) {
  var oldDepth = depth;
  increaseDepth();
  return parent.registerCallback(zone, () {
    depth = oldDepth;
    return f();
  });
}

dynamic Function(dynamic) registerUnaryCallback(
    Zone self, ZoneDelegate parent, Zone zone, f) {
  var oldDepth = depth;
  increaseDepth();
  return parent.registerUnaryCallback(zone, (x) {
    depth = oldDepth;
    return f(x);
  });
}

dynamic Function(dynamic, dynamic) registerBinaryCallback(
    Zone self, ZoneDelegate parent, Zone zone, f) {
  var oldDepth = depth;
  increaseDepth();
  return parent.registerBinaryCallback(zone, (x, y) {
    depth = oldDepth;
    return f(x, y);
  });
}

sm(Zone self, ZoneDelegate parent, Zone zone, f) {
  var oldDepth = depth;
  increaseDepth();
  return parent.scheduleMicrotask(zone, () {
    depth = oldDepth;
    return f();
  });
}

main() {
  asyncStart();
  var desc = new ZoneSpecification(
      registerCallback: registerCallback,
      registerUnaryCallback: registerUnaryCallback,
      registerBinaryCallback: registerBinaryCallback,
      scheduleMicrotask: sm);
  var future = runZoned(runTests, zoneSpecification: desc);
  future.then((_) => asyncEnd());
}
