// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import 'dart:async';
import 'dart:isolate';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'wait_for_event_helper.dart';

// Tests that waitForEvent() returns on an Isolate message.

messageSender(SendPort s) {
  new Timer(const Duration(seconds: 1), () {
    s.send(true);
  });
}

main() {
  initWaitForEvent();
  asyncStart();
  bool flag1 = false;
  bool flag2 = false;
  ReceivePort r = new ReceivePort();
  Isolate.spawn(messageSender, r.sendPort).then((Isolate i) {
    r.listen((message) {
      flag1 = true;
    });
    Expect.isFalse(flag1);
    waitForEvent();
    Expect.isTrue(flag1);
    r.close();
    flag2 = true;
  });
  Expect.isFalse(flag1);
  Expect.isFalse(flag2);
  waitForEvent();
  Expect.isTrue(flag1);
  Expect.isTrue(flag2);
  asyncEnd();
}
