// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates are spawned.

library IsolateNegativeTest;
import "package:expect/expect.dart";
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

void entry(SendPort replyTo) {
  replyTo.send("foo");
}

main() {
  test("ensure isolate code is executed", () {
    ReceivePort response = new ReceivePort();
    Isolate.spawn(entry, response.sendPort);
    response.first.then(expectAsync1((message) {
      expect("Expected fail", isTrue);   // <=-------- Should fail here.
    }));
  });
}
