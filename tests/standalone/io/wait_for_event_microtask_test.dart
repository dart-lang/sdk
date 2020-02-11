// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'wait_for_event_helper.dart';

// Tests that microtasks are run before waitForEvent() blocks.

main() {
  initWaitForEvent();
  asyncStart();
  bool flag = false;
  scheduleMicrotask(() {
    flag = true;
    asyncEnd();
  });
  Expect.isFalse(flag);
  waitForEvent(timeout: const Duration(milliseconds: 10));
  Expect.isTrue(flag);
}
