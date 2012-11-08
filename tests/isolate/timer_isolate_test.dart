// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multiple_timer_test;

import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

const int TIMEOUT = 100;

createTimer() {
  port.receive((msg, replyTo) {
    new Timer(TIMEOUT, (_) {
      replyTo.send("timer_fired");
    });
  });
}

main() {
  test("timer in isolate", () {
    int startTime;
    int endTime;
    
    port.receive(expectAsync2((msg, _) {
      expect("timer_fired", msg);
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      expect(endTime - startTime, greaterThanOrEqualTo(TIMEOUT));
      port.close();
    }));
    
    startTime = (new Date.now()).millisecondsSinceEpoch;
    var sendPort = spawnFunction(createTimer);
    sendPort.send("sendPort", port.toSendPort());
  });
}
