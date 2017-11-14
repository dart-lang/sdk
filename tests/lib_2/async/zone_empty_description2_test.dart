// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

testEmptyZoneSpecification() {
  Expect.identical(Zone.root, Zone.current);
  Zone forked = Zone.current.fork();
  Expect.isFalse(identical(Zone.root, forked));

  asyncStart();
  bool timerDidRun = false;
  forked.createTimer(const Duration(milliseconds: 20), () {
    // The createTimer function on the Zone binds the closures.
    Expect.identical(forked, Zone.current);
    timerDidRun = true;
    asyncEnd();
  });
  Expect.identical(Zone.root, Zone.current);

  asyncStart();
  int periodicTimerCount = 0;
  forked.createPeriodicTimer(const Duration(milliseconds: 20), (Timer timer) {
    periodicTimerCount++;
    if (periodicTimerCount == 4) {
      timer.cancel();
      asyncEnd();
    }
    // The createPeriodicTimer function on the Zone binds the closures.
    Expect.identical(forked, Zone.current);
  });
  Expect.identical(Zone.root, Zone.current);
}

main() {
  testEmptyZoneSpecification();
}
