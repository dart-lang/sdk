// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Tests that the microtasks for a message handler are run before
// waitForEventSync() returns.

main() {
  asyncStart();
  bool flag = false;
  Timer.run(() {
    scheduleMicrotask(() {
      flag = true;
      asyncEnd();
    });
  });
  Expect.isFalse(flag);
  waitForEventSync();
  Expect.isTrue(flag);
}
