// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can communicate to isolates
// other than the main isolate.

library CrossIsolateMessageTest;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

/*
 * Everything starts in the main-isolate (in the main-method).
 * The main isolate spawns two isolates: isolate1 (with entry point
 * 'crossIsolate1') and isolate2 (with entry point 'crossIsolate2').
 *
 * The main-isolate creates a new message-box and sends its sink to both
 * isolates. Whenever isolate1 or isolate2 send something to the main-isolate
 * they will use this sink.
 * Isolate2 stores the sink and replies with a new sink (sink2b) it created.
 * Isolate1 stores the sink and waits for another message.
 * Main receives isolate2's sink2b and sends it to isolate1.
 * Isolate1 stores this sink as "otherIsolate" and send a new sink (sink1b) to
 * the main isolate.
 * Main receives sink1b and sents a message "fromMain, 42" to sink1b.
 * isolate1 receives this message, modifies it (adding 58 to 42) and forwards
 * it to isolate2 (otherIsolate).
 * isolate2 receives the message, modifies it (adding 399), and sends it to
 * the main isolate.
 * The main-isolate receives it, verifies that the result is 499 and ends the
 * test.
 */

void crossIsolate1() {
  bool first = true;
  IsolateSink mainIsolate;
  var subscription = stream.listen((msg) {
    if (first) {
      first = false;
      mainIsolate = msg;
      return;
    }
    IsolateSink otherIsolate = msg;
    MessageBox box = new MessageBox();
    box.stream.single.then((msg) {
      expect(msg[0], "fromMain");
      otherIsolate.add(["fromIsolate1", msg[1] + 58]);  // 100;
      otherIsolate.close();
      box.stream.close();
    });
    mainIsolate.add(['ready1', box.sink]);
    stream.close();
  });
}

void crossIsolate2() {
  var subscription;
  subscription = stream.listen((msg) {
    IsolateSink mainIsolate = msg;
    MessageBox box = new MessageBox();
    box.stream.listen((msg) {
      expect(msg[0], "fromIsolate1");
      mainIsolate.add(["fromIsolate2", msg[1] + 399]);  // 499;
      mainIsolate.close();
      box.stream.close();
    });
    mainIsolate.add(['ready2', box.sink]);
    subscription.cancel();
  });
}

main() {
  test("share sink, and send message cross isolates ", () {
    IsolateSink sink1 = streamSpawnFunction(crossIsolate1);
    IsolateSink sink2 = streamSpawnFunction(crossIsolate2);
    // Create a new sink and send it to isolate2.
    MessageBox box = new MessageBox();
    sink1.add(box.sink);
    sink2.add(box.sink);
    int msgNumber = 0;

    bool isReady1 = false;
    bool isReady2 = false;
    bool hasSentMessage = false;

    Function ready1 = expectAsync0(() => isReady1 = true);
    Function ready2 = expectAsync0(() => isReady2 = true);
    Function fromIsolate2 = expectAsync1((data) {
      expect(data, 499);
    });
    IsolateSink sink1b;
    IsolateSink sink2b;

    box.stream.listen((msg) {
      switch (msg[0]) {
        case 'ready1': ready1(); sink1b = msg[1]; break;
        case 'ready2':
          ready2();
          sink2b = msg[1];
          sink1.add(sink2b);
          break;
        case 'fromIsolate2': fromIsolate2(msg[1]); break;
        default: throw "bad message";
      }
      if (isReady1 && isReady2 && !hasSentMessage) {
        hasSentMessage = true;
        sink1b.add(["fromMain", 42]);
        sink1b.close();
      }
    });
  });
}
