// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

testForkedZone(Zone forked) {
  var result;
  result = forked.run(() {
    Expect.identical(forked, Zone.current);
    return 499;
  });
  Expect.equals(499, result);
  Expect.identical(Zone.ROOT, Zone.current);

  result = forked.runUnary((x) {
    Expect.equals(42, x);
    Expect.identical(forked, Zone.current);
    return -499;
  }, 42);
  Expect.equals(-499, result);
  Expect.identical(Zone.ROOT, Zone.current);

  bool runGuardedDidRun = false;
  forked.runGuarded(() {
    runGuardedDidRun = true;
    Expect.identical(forked, Zone.current);
  });
  Expect.identical(Zone.ROOT, Zone.current);
  Expect.isTrue(runGuardedDidRun);

  runGuardedDidRun = false;
  forked.runUnaryGuarded((x) {
    runGuardedDidRun = true;
    Expect.equals(42, x);
    Expect.identical(forked, Zone.current);
  }, 42);
  Expect.identical(Zone.ROOT, Zone.current);
  Expect.isTrue(runGuardedDidRun);

  var callback = () => 499;
  Expect.identical(callback, forked.registerCallback(callback));
  Expect.identical(Zone.ROOT, Zone.current);

  var callback1 = (x) => 42 + x;
  Expect.identical(callback1, forked.registerUnaryCallback(callback1));
  Expect.identical(Zone.ROOT, Zone.current);

  asyncStart();
  bool asyncDidRun = false;
  forked.scheduleMicrotask(() {
    Expect.identical(forked, Zone.current);
    asyncDidRun = true;
    asyncEnd();
  });
  Expect.isFalse(asyncDidRun);
  Expect.identical(Zone.ROOT, Zone.current);

  asyncStart();
  bool timerDidRun = false;
  forked.createTimer(const Duration(milliseconds: 0), () {
    Expect.identical(forked, Zone.current);
    timerDidRun = true;
    asyncEnd();
  });
  Expect.identical(Zone.ROOT, Zone.current);
}

main() {
  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked = Zone.current.fork();
  Expect.isFalse(identical(Zone.ROOT, forked));
  testForkedZone(forked);
  Zone forkedChild = forked.fork();
  testForkedZone(forkedChild);
}
