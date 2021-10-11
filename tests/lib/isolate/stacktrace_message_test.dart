// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import "package:expect/expect.dart";

// Test that StackTrace objects can be sent between isolates spawned from
// the same isolate using Isolate.spawn.

void main() async {
  final reply = ReceivePort();
  Isolate.spawn(runTest, reply.sendPort);
  final pair = await reply.first;
  final stack = pair[0] as StackTrace;
  final stackString = pair[1] as String;
  Expect.isNotNull(stack);
  Expect.equals(stackString, "$stack");
}

runTest(SendPort sendport) {
  try {
    throw 'sorry';
  } catch (e, stack) {
    sendport.send([stack, "$stack"]);
  }
}
