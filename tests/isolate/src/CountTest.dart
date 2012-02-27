// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("CountTest");
#import('dart:isolate');
#import("TestFramework.dart");

class TestIsolate extends Isolate {

  TestIsolate() : super();

  void main() {
    int count = 0;
    this.port.receive((int message, SendPort replyTo) {
      if (message == -1) {
        Expect.equals(10, count);
        replyTo.send(-1, null);
        this.port.close();
        return;
      }

      Expect.equals(count, message);
      count++;
      replyTo.send(message * 2, null);
    });
  }
}

void test(TestExpectation expect) {
  int count = 0;
  expect.completes(new TestIsolate().spawn()).then((SendPort remote) {
    ReceivePort local = new ReceivePort();
    SendPort reply = local.toSendPort();

    local.receive(expect.runs2((int message, SendPort replyTo) {
      if (message == -1) {
        Expect.equals(11, count);
        local.close();
        expect.succeeded();
        return;
      }

      Expect.equals((count - 1) * 2, message);
      remote.send(count++, reply);
      if (count == 10) {
        remote.send(-1, reply);
      }
    }));
    remote.send(count++, reply);
  });
}

void main() {
  runTests([test]);
}



