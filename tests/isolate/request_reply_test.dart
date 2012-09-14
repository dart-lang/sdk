// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("RequestReplyTest");

#import("dart:isolate");
#import('../../pkg/unittest/unittest.dart');

void entry() {
  port.receive((message, SendPort replyTo) {
    replyTo.send(message + 87);
    port.close();
  });
}

void main() {
  test("call", () {
    SendPort port = spawnFunction(entry);
    port.call(42).then(expectAsync1((message) {
      Expect.equals(42 + 87, message);
    }));
  });

  test("send", () {
    SendPort port = spawnFunction(entry);
    ReceivePort reply = new ReceivePort();
    port.send(99, reply.toSendPort());
    reply.receive(expectAsync2((message, replyTo) {
      Expect.equals(99 + 87, message);
      reply.close();
    }));
  });
}
