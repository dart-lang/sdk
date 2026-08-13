// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multiple_timer_test;

import 'dart:isolate';
import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

const Duration timeout = const Duration(milliseconds: 100);

void createTimer(replyTo) {
  Timer(timeout, () {
    replyTo.send("timer_fired");
  });
}

void main() {
  asyncStart();
  Stopwatch stopwatch = new Stopwatch();
  ReceivePort port = new ReceivePort();

  port.first.then((msg) {
    Expect.equals("timer_fired", msg);
    Expect.isTrue(stopwatch.elapsedMilliseconds >= timeout.inMilliseconds);
    asyncEnd();
  });

  stopwatch.start();
  var remote = Isolate.spawn(createTimer, port.sendPort);
}
