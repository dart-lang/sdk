// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'wait_for_event_helper.dart';

// Tests that waitForEvent() drains microtasks before blocking even when
// called from a microtask.

main() {
  initWaitForEvent();
  asyncStart();
  bool flag1 = false;
  bool flag2 = false;
  scheduleMicrotask(() {
    scheduleMicrotask(() {
      flag1 = true;
      asyncEnd();
    });
    Expect.isFalse(flag1);
    waitForEvent(timeout: const Duration(milliseconds: 10));
    Expect.isTrue(flag1);
    flag2 = true;
  });
  Expect.isFalse(flag1);
  Expect.isFalse(flag2);
  waitForEvent(timeout: const Duration(milliseconds: 10));
  Expect.isTrue(flag1);
  Expect.isTrue(flag2);
}
