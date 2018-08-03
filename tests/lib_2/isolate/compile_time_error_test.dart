// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that errors thrown from isolates are
// processed correctly and don't result in crashes.

library Isolate3NegativeTest;

import 'dart:isolate';
import 'dart:async';
import "package:async_helper/async_helper.dart";

class TestClass {
  TestClass.named(num this.fld1)
  // Should cause a compilation error (for the spawned isolate). It is a
  // runtime error for the test.
    : fld2 = this.fld1 // //# 01: compile-time error
  ;
  num fld1;
  num fld2;
}

void entry(SendPort replyTo) {
  var tmp = new TestClass.named(10);
  replyTo.send("done");
}

main() {
  asyncStart();
  ReceivePort response = new ReceivePort();
  Isolate.spawn(entry, response.sendPort);
  response.first.then((_) {
    asyncEnd();
  });
}
