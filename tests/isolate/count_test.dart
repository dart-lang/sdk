// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("CountTest");
#import('dart:isolate');
#import('../../pkg/unittest/lib/unittest.dart');

void countMessages() {
  int count = 0;
  port.receive((int message, SendPort replyTo) {
    if (message == -1) {
      Expect.equals(10, count);
      replyTo.send(-1, null);
      port.close();
      return;
    }
    Expect.equals(count, message);
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
        Expect.equals(11, count);
        local.close();
        return;
      }

      Expect.equals((count - 1) * 2, message);
      remote.send(count++, reply);
      if (count == 10) {
        remote.send(-1, reply);
      }
    }, count: 11));
    remote.send(count++, reply);
  });
}
