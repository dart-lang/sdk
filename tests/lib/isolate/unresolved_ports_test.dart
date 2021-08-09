// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// spawns multiple isolates and sends unresolved ports between them.
library unresolved_ports;

import 'dart:async';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

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

Future spawnFunction(function) {
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
  // Message chain with unresolved ports
  ReceivePort port = new ReceivePort();
  asyncStart();
  port.listen((msg) {
    Expect.equals(
        msg,
        'main says: Beth, find out if Tim is coming.'
        '\nBeth says: Tim are you coming? And Bob?'
        '\nTim says: Can you tell "main" that we are all coming?'
        '\nBob says: we are all coming!');
    Expect.isFalse(failForNegativeTest);
    port.close();
    asyncEnd();
  });

  spawnFunction(timIsolate).then((tim) {
    spawnFunction(bethIsolate).then((beth) {
      beth.send(
          ['main says: Beth, find out if Tim is coming.', tim, port.sendPort]);
    });
  });
}

void main([args, port]) => baseTest();
