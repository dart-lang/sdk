// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can spawn other isolates.

library NestedSpawnTest;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

void isolateA(message) {
  message.add("isolateA");
  Isolate.spawn(isolateB, message);
}

void isolateB(message) {
  message.add("isolateB");
  message[0].send(message);
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("spawned isolates can spawn nested isolates", () {
    ReceivePort port = new ReceivePort();
    Isolate.spawn(isolateA, [port.sendPort, "main"]);
    return port.first.then((message) {
      expect("main", message[1]);
      expect("isolateA", message[2]);
      expect("isolateB", message[3]);
    });
  });
}
