// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can spawn other isolates and
// that the nested isolates can communicate with the main once the spawner has
// disappeared.

library NestedSpawn2Test;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

void _call(IsolateSink sink, msg, void onreceive(m, replyTo)) {
  final box = new MessageBox();
  sink.add([msg, box.sink]);
  sink.close();
  box.stream.single.then((msg) {
    onreceive(msg[0], msg[1]);
  });
}

void _receive(IsolateStream stream, void onreceive(m, replyTo)) {
  stream.single.then((msg) {
    onreceive(msg[0], msg[1]);
  });
}

void isolateA() {
  _receive(stream, (msg, replyTo) {
    expect(msg, "launch nested!");
    IsolateSink sink = streamSpawnFunction(isolateB);
    sink.add(replyTo);
    sink.close();
    stream.close();
  });
}

String msg0 = "0 there?";
String msg1 = "1 Yes.";
String msg2 = "2 great. Think the other one is already dead?";
String msg3 = "3 Give him some time.";
String msg4 = "4 now?";
String msg5 = "5 Now.";
String msg6 = "6 Great. Bye";

void isolateB() {
  stream.single.then((mainPort) {
    // Do a little ping-pong dance to give the intermediate isolate
    // time to die.
    _call(mainPort, msg0, ((msg, replyTo) {
      expect(msg[0], "1");
      _call(replyTo, msg2, ((msg, replyTo) {
        expect(msg[0], "3");
        _call(replyTo, msg4, ((msg, replyTo) {
          expect(msg[0], "5");
          replyTo.add(msg6);
          replyTo.close();
        }));
      }));
    }));
  });
}

main() {
  test("spawned isolate can spawn other isolates", () {
    IsolateSink sink = streamSpawnFunction(isolateA);
    _call(sink, "launch nested!", expectAsync2((msg, replyTo) {
      expect(msg[0], "0");
      _call(replyTo, msg1, expectAsync2((msg, replyTo) {
        expect(msg[0], "2");
        _call(replyTo, msg3, expectAsync2((msg, replyTo) {
          expect(msg[0], "4");
          _call(replyTo, msg5, expectAsync2((msg, replyTo) {
            expect(msg[0], "6");
          }));
        }));
      }));
    }));
  });
}
