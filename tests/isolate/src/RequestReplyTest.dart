// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("RequestReplyTest");
#import("dart:isolate");
#import("TestFramework.dart");

class TestIsolate extends Isolate {

  TestIsolate() : super();

  void main() {
    this.port.receive((message, SendPort replyTo) {
      replyTo.send(message + 87);
      this.port.close();
    });
  }

}

void testCall(TestExpectation expect) {
  expect.completes(new TestIsolate().spawn()).then((SendPort port) {
    port.call(42).then(expect.runs1((message) {
      Expect.equals(42 + 87, message);
      expect.succeeded();
    }));
  });
}

void testSend(TestExpectation expect) {
  expect.completes(new TestIsolate().spawn()).then((SendPort port) {
    ReceivePort reply = new ReceivePort();
    port.send(99, reply.toSendPort());
    reply.receive(expect.runs2((message, replyTo) {
      Expect.equals(99 + 87, message);
      reply.close();
      expect.succeeded();
    }));
  });
}

void main() {
  runTests([testCall, testSend]);
}
