// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates are spawned.

library IsolateNegativeTest;

import "package:expect/expect.dart";
import 'dart:isolate';
import "package:async_helper/async_helper.dart";

void entry(SendPort replyTo) {
  var message = "foo";
  message = "bar"; // //# 01: runtime error
  replyTo.send(message);
}

main() {
  asyncStart();
  ReceivePort response = new ReceivePort();
  Isolate.spawn(entry, response.sendPort);
  response.first.then((message) {
    Expect.equals("foo", message);
    asyncEnd();
  });
}
