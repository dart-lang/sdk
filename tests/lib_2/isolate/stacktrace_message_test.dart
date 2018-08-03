// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// Test that StackTrace objects can be sent between isolates spawned from
// the same isolate using Isolate.spawn.

void main() {
  asyncStart();
  ReceivePort reply = new ReceivePort();
  Isolate.spawn(runTest, reply.sendPort);
  reply.first.then((pair) {
    StackTrace stack = pair[0];
    String stackString = pair[1];
    if (stack == null) {
      print("Failed to send stack-trace");
      print(stackString);
      Expect.fail("Sending stack-trace");
    }
    Expect.equals(stackString, "!$stack");
    print(stack);
    asyncEnd();
  });
}

runTest(SendPort sendport) {
  try {
    throw 'sorry';
  } catch (e, stack) {
    try {
      sendport.send([stack, "$stack"]);
      print("Stacktrace sent");
    } catch (e, s) {
      print("Stacktrace not sent");
      sendport.send([null, "$e\n$s"]);
    }
  }
}
