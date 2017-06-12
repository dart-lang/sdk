// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// spawns multiple isolates and sends unresolved ports between them.
library unresolved_ports;

import 'dart:async';
import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

// This test does the following:
//  - main spawns two isolates: 'tim' and 'beth'
//  - 'tim' spawns an isolate: 'bob'
//  - main starts a message chain:
//       main -> beth -> tim -> bob -> main
//    by giving 'beth' a send-port to 'tim'.

bethIsolate(init) {
  ReceivePort port = initIsolate(init);
  // TODO(sigmund): use expectAsync when it is OK to use it within an isolate
  // (issue #6856)
  port.first.then((msg) => msg[1]
      .send(['${msg[0]}\nBeth says: Tim are you coming? And Bob?', msg[2]]));
}

timIsolate(init) {
  ReceivePort port = initIsolate(init);
  spawnFunction(bobIsolate).then((bob) {
    port.first.then((msg) => bob.send([
          '${msg[0]}\nTim says: Can you tell "main" that we are all coming?',
          msg[1]
        ]));
  });
}

bobIsolate(init) {
  ReceivePort port = initIsolate(init);
  port.first
      .then((msg) => msg[1].send('${msg[0]}\nBob says: we are all coming!'));
}

Future<SendPort> spawnFunction(function) {
  ReceivePort init = new ReceivePort();
  Isolate.spawn(function, init.sendPort);
  return init.first;
}

ReceivePort initIsolate(SendPort starter) {
  ReceivePort port = new ReceivePort();
  starter.send(port.sendPort);
  return port;
}

baseTest({bool failForNegativeTest: false}) {
  test('Message chain with unresolved ports', () {
    ReceivePort port = new ReceivePort();
    port.listen(expectAsync((msg) {
      expect(
          msg,
          equals('main says: Beth, find out if Tim is coming.'
              '\nBeth says: Tim are you coming? And Bob?'
              '\nTim says: Can you tell "main" that we are all coming?'
              '\nBob says: we are all coming!'));
      expect(failForNegativeTest, isFalse);
      port.close();
    }));

    spawnFunction(timIsolate).then((tim) {
      spawnFunction(bethIsolate).then((beth) {
        beth.send([
          'main says: Beth, find out if Tim is coming.',
          tim,
          port.sendPort
        ]);
      });
    });
  });
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  baseTest();
}
