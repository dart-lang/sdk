// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("RequestReplyTest");

#import("dart:isolate");
#import('../../../lib/unittest/unittest.dart');

class TestIsolate extends Isolate {

  TestIsolate() : super();

  void main() {
    this.port.receive((message, SendPort replyTo) {
      replyTo.send(message + 87);
      this.port.close();
    });
  }

}

void main() {
  test("call", () {
    new TestIsolate().spawn().then(expectAsync1((SendPort port) {
      port.call(42).then(expectAsync1((message) {
        Expect.equals(42 + 87, message);
      }));
    }));
  });

  test("send", () {
    new TestIsolate().spawn().then(expectAsync1((SendPort port) {
      ReceivePort reply = new ReceivePort();
      port.send(99, reply.toSendPort());
      reply.receive(expectAsync2((message, replyTo) {
        Expect.equals(99 + 87, message);
        reply.close();
      }));
    }));
  });
}
