// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'wait_for_event_helper.dart';

// Tests that waitForEvent() works when called from a message handler.

main() {
  initWaitForEvent();
  asyncStart();
  bool flag1 = false;
  bool flag2 = false;
  bool flag3 = false;
  bool flag4 = false;
  Timer.run(() {
    Timer.run(() {
      Timer.run(() {
        Timer.run(() {
          flag1 = true;
          asyncEnd();
        });
        Expect.isFalse(flag1);
        Expect.isFalse(flag2);
        Expect.isFalse(flag3);
        Expect.isFalse(flag4);
        waitForEvent();
        Expect.isTrue(flag1);
        Expect.isFalse(flag2);
        Expect.isFalse(flag3);
        Expect.isFalse(flag4);
        flag2 = true;
      });
      Expect.isFalse(flag1);
      Expect.isFalse(flag2);
      Expect.isFalse(flag3);
      Expect.isFalse(flag4);
      waitForEvent();
      Expect.isTrue(flag1);
      Expect.isTrue(flag2);
      Expect.isFalse(flag3);
      Expect.isFalse(flag4);
      flag3 = true;
    });
    Expect.isFalse(flag1);
    Expect.isFalse(flag2);
    Expect.isFalse(flag3);
    Expect.isFalse(flag4);
    waitForEvent();
    Expect.isTrue(flag1);
    Expect.isTrue(flag2);
    Expect.isTrue(flag3);
    Expect.isFalse(flag4);
    flag4 = true;
  });
  Expect.isFalse(flag1);
  Expect.isFalse(flag2);
  Expect.isFalse(flag3);
  Expect.isFalse(flag4);
  waitForEvent();
  Expect.isTrue(flag1);
  Expect.isTrue(flag2);
  Expect.isTrue(flag3);
  Expect.isTrue(flag4);
}
