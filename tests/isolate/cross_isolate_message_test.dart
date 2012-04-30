// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can communicate to isolates
// other than the main isolate.

#library('CrossIsolateMessageTest');
#import('dart:isolate');
#import('../../lib/unittest/unittest.dart');

class CrossIsolate1 extends Isolate {
  CrossIsolate1() : super.heavy();

  void main() {
    this.port.receive((msg, replyTo) {
      SendPort otherIsolate = msg;
      ReceivePort receivePort = new ReceivePort();
      receivePort.receive((msg, replyTo) {
        otherIsolate.send(msg + 58, null);  // 100.
        receivePort.close();
      });
      replyTo.send(['ready', receivePort.toSendPort()]);
      this.port.close();
    });
  }
}

// CrossIsolate2 is nearly the same as CrossIsolate1, but contains a
// different constant.
class CrossIsolate2 extends Isolate {
  CrossIsolate2() : super.heavy();

  void main() {
    this.port.receive((msg, replyTo) {
      SendPort mainIsolate = msg;
      ReceivePort receivePort = new ReceivePort();
      receivePort.receive((msg, replyTo) {
        mainIsolate.send(msg + 399, null); // 499.
        receivePort.close();
      });
      replyTo.send(['ready', receivePort.toSendPort()]);
      this.port.close();
    });
  }
}

main() {
  test("share port, and send message cross isolates ", () {
    // Create CrossIsolate1 and CrossIsolate2.
    new CrossIsolate1().spawn().then(expectAsync1((SendPort port1) {
      new CrossIsolate2().spawn().then(expectAsync1((SendPort port2) {
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
      }));
    }));
  });
}
