// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-DtestString=testValue -DtestInt=-0xfeed -DtestBool=false

import "dart:isolate";

import "package:expect/expect.dart";

import "isolate_from_env_shared.dart";

void isolateEntryPoint(SendPort replyPort) {
  try {
    checkEnv();
    replyPort.send("OK");
  } catch (e, st) {
    replyPort.send("ERROR: $e\n$st");
  }
}

void main() async {
  // 1. Verify in main isolate.
  checkEnv();

  // 2. Verify in child isolate spawned via Isolate.spawn.
  {
    final receivePort = ReceivePort();
    await Isolate.spawn(isolateEntryPoint, receivePort.sendPort);
    final result = await receivePort.first;
    Expect.equals("OK", result);
  }

  // 3. Verify in child isolate spawned via Isolate.run.
  {
    final result = await Isolate.run(() {
      checkEnv();
      return "OK";
    });
    Expect.equals("OK", result);
  }
}
