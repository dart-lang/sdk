// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Tests that example code in the doc comment for waitForEventSync is okay.

main() {
  asyncStart();
  bool condition = false;

  new Timer(const Duration(seconds: 2), () {
    asyncEnd();
    condition = true;
  });

  Duration timeout = const Duration(milliseconds: 100);
  Timer.run(() {}); // Ensure that there is at least one event.
  Stopwatch s = new Stopwatch()..start();
  while (!condition) {
    if (s.elapsed > timeout) {
      break;
    }
    waitForEventSync(timeout: timeout);
  }
  s.stop();

  Expect.isFalse(condition);
  while (!condition) {
    waitForEventSync();
  }
  Expect.isTrue(condition);
}
