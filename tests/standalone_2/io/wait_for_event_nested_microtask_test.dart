// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Tests that waitForEventSync() drains microtasks before blocking even when
// called from a microtask.

main() {
  asyncStart();
  bool flag1 = false;
  bool flag2 = false;
  scheduleMicrotask(() {
    scheduleMicrotask(() {
      flag1 = true;
      asyncEnd();
    });
    Expect.isFalse(flag1);
    waitForEventSync(timeout: const Duration(milliseconds: 10));
    Expect.isTrue(flag1);
    flag2 = true;
  });
  Expect.isFalse(flag1);
  Expect.isFalse(flag2);
  waitForEventSync(timeout: const Duration(milliseconds: 10));
  Expect.isTrue(flag1);
  Expect.isTrue(flag2);
}
