// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Tests that waitForEventSync() returns on an Isolate message.

messageSender(SendPort s) {
  new Timer(const Duration(seconds: 1), () {
    s.send(true);
  });
}

main() {
  asyncStart();
  bool flag1 = false;
  bool flag2 = false;
  ReceivePort r = new ReceivePort();
  Isolate.spawn(messageSender, r.sendPort).then((Isolate i) {
    r.listen((message) {
      flag1 = true;
    });
    Expect.isFalse(flag1);
    waitForEventSync();
    Expect.isTrue(flag1);
    r.close();
    flag2 = true;
  });
  Expect.isFalse(flag1);
  Expect.isFalse(flag2);
  waitForEventSync();
  Expect.isTrue(flag1);
  Expect.isTrue(flag2);
  asyncEnd();
}
