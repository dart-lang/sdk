// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages with static
// native functions.

library MessageTest;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void echoMain(msg) {
  SendPort replyTo = msg[0];
  SendPort pong = msg[1];
  ReceivePort port = new ReceivePort();
  replyTo.send(port.sendPort);
  port.listen((msg) {
    if (msg == "halt") {
      port.close();
    } else {
      pong.send(msg);
    }
  });
}

void runTests(SendPort ping, Queue checks) {
  ping.send("abc");
  checks.add((x) => Expect.equals("abc", x));

  ping.send(int.parse);
  checks.add((x) => Expect.identical(int.parse, x));

  ping.send(identityHashCode);
  checks.add((x) => Expect.identical(identityHashCode, x));

  ping.send(identical);
  checks.add((x) => Expect.identical(identical, x));
}

void main() async {
  asyncStart();
  Queue checks = new Queue();
  ReceivePort testPort = new ReceivePort();
  Completer completer = new Completer();

  testPort.listen((msg) {
    Function check = checks.removeFirst();
    check(msg);
    if (checks.isEmpty) {
      completer.complete();
      testPort.close();
    }
  });

  ReceivePort initialReplyPort = new ReceivePort();

  Isolate i = await Isolate
      .spawn(echoMain, [initialReplyPort.sendPort, testPort.sendPort]);
  SendPort ping = await initialReplyPort.first;
  runTests(ping, checks);
  Expect.isTrue(checks.length > 0);
  await completer.future;
  ping.send("halt");
  asyncEnd();
}
