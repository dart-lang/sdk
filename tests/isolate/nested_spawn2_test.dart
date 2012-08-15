// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can spawn other isolates and
// that the nested isolates can communicate with the main once the spawner has
// disappeared.

#library('NestedSpawn2Test');
#import("dart:isolate");
#import('../../pkg/unittest/unittest.dart');

void isolateA() {
  port.receive((msg, replyTo) {
    Expect.equals("launch nested!", msg);
    SendPort p = spawnFunction(isolateB);
    p.send(replyTo, null);
    port.close();
  });
}

String msg0 = "0 there?";
String msg1 = "1 Yes.";
String msg2 = "2 great. Think the other one is already dead?";
String msg3 = "3 Give him some time.";
String msg4 = "4 now?";
String msg5 = "5 Now.";
String msg6 = "6 Great. Bye";

void _call(SendPort p, msg, void onreceive(m, replyTo)) {
  final replyTo = new ReceivePort();
  p.send(msg, replyTo.toSendPort());
  replyTo.receive((m, r) {
    replyTo.close();
    onreceive(m, r);
  });
}

void isolateB() {
  port.receive((mainPort, replyTo) {
    port.close();
    // Do a little ping-pong dance to give the intermediate isolate
    // time to die.
    _call(mainPort, msg0, ((msg, replyTo) {
      Expect.equals("1", msg[0]);
      _call(replyTo, msg2, ((msg, replyTo) {
        Expect.equals("3", msg[0]);
        _call(replyTo, msg4, ((msg, replyTo) {
          Expect.equals("5", msg[0]);
          replyTo.send(msg6, null);
        }));
      }));
    }));
  });
}

main() {
  test("spawned isolate can spawn other isolates", () {
    SendPort port = spawnFunction(isolateA);
    _call(port, "launch nested!", expectAsync2((msg, replyTo) {
      Expect.equals("0", msg[0]);
      _call(replyTo, msg1, expectAsync2((msg, replyTo) {
        Expect.equals("2", msg[0]);
        _call(replyTo, msg3, expectAsync2((msg, replyTo) {
          Expect.equals("4", msg[0]);
          _call(replyTo, msg5, expectAsync2((msg, replyTo) {
            Expect.equals("6", msg[0]);
          }));
        }));
      }));
    }));
  });
}
