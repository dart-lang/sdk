// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Dart test program for testing that isolates can spawn other isolates.

library NestedSpawnTest;

import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

void isolateA(message) {
  message.add("isolateA");
  Isolate.spawn(isolateB, message);
}

void isolateB(message) {
  message.add("isolateB");
  message[0].send(message);
}

void main([args, port]) {
  // spawned isolates can spawn nested isolates
  ReceivePort port = new ReceivePort();
  Isolate.spawn(isolateA, [port.sendPort, "main"]);
  asyncStart();
  port.first.then((message) {
    Expect.equals("main", message[1]);
    Expect.equals("isolateA", message[2]);
    Expect.equals("isolateB", message[3]);
    asyncEnd();
  });
}
