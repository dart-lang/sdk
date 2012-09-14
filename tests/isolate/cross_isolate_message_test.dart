// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can communicate to isolates
// other than the main isolate.

#library('CrossIsolateMessageTest');
#import('dart:isolate');
#import('../../pkg/unittest/lib/unittest.dart');

void crossIsolate1() {
  port.receive((msg, replyTo) {
    SendPort otherIsolate = msg;
    ReceivePort receivePort = new ReceivePort();
    receivePort.receive((msg, replyTo) {
      otherIsolate.send(msg + 58, null);  // 100.
      receivePort.close();
    });
    replyTo.send(['ready', receivePort.toSendPort()]);
    port.close();
  });
}

// crossIsolate2 is nearly the same as crossIsolate1, but contains a
// different constant.
void crossIsolate2() {
  port.receive((msg, replyTo) {
    SendPort mainIsolate = msg;
    ReceivePort receivePort = new ReceivePort();
    receivePort.receive((msg, replyTo) {
      mainIsolate.send(msg + 399, null); // 499.
      receivePort.close();
    });
    replyTo.send(['ready', receivePort.toSendPort()]);
    port.close();
  });
}

main() {
  test("share port, and send message cross isolates ", () {
    SendPort port1 = spawnFunction(crossIsolate1);
    SendPort port2 = spawnFunction(crossIsolate2);
    // Create a new receive port and send it to isolate2.
    ReceivePort myPort = new ReceivePort();
    port2.call(myPort.toSendPort()).then(expectAsync1((msg) {
      Expect.equals("ready", msg[0]);
      // Send port of isolate2 to isolate1.
      port1.call(msg[1]).then(expectAsync1((msg) {
        Expect.equals("ready", msg[0]);
        myPort.receive(expectAsync2((msg, replyTo) {
          Expect.equals(499, msg);
          myPort.close();
        }));
        msg[1].send(42, null);
      }));
    }));
  });
}
