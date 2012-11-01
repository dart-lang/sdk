// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library CountTest;
import '../../pkg/unittest/lib/unittest.dart';
import 'dart:isolate';

void countMessages() {
  int count = 0;
  port.receive((int message, SendPort replyTo) {
    if (message == -1) {
      expect(count, 10);
      replyTo.send(-1, null);
      port.close();
      return;
    }
    expect(message, count);
    count++;
    replyTo.send(message * 2, null);
  });
}

void main() {
  test("count 10 consecutive messages", () {
    int count = 0;
    SendPort remote = spawnFunction(countMessages);
    ReceivePort local = new ReceivePort();
    SendPort reply = local.toSendPort();

    local.receive(expectAsync2((int message, SendPort replyTo) {
      if (message == -1) {
        expect(count, 11);
        local.close();
        return;
      }

      expect(message, (count - 1) * 2);
      remote.send(count++, reply);
      if (count == 10) {
        remote.send(-1, reply);
      }
    }, 11));
    remote.send(count++, reply);
  });
}
