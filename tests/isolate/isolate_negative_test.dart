// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates are spawned.

library IsolateNegativeTest;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

void entry() {
  port.receive((ignored, replyTo) {
    replyTo.send("foo", null);
  });
}

main() {
  test("ensure isolate code is executed", () {
    SendPort port = spawnFunction(entry);
    port.call("foo").then(expectAsync1((message) {
      expect("Expected fail", isTrue);   // <=-------- Should fail here.
    }));
  });
}
