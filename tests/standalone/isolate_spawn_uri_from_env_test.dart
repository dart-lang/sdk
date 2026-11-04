// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-DtestString=testValue -DtestInt=-0xfeed -DtestBool=false

import "dart:io";
import "dart:isolate";

import "package:expect/expect.dart";

import "isolate_from_env_shared.dart";

void main(List<String> args, dynamic message) async {
  if (args.contains("--child")) {
    try {
      checkEnv();
      (message as SendPort).send("OK");
    } catch (e, st) {
      (message as SendPort).send("ERROR: $e\n$st");
    }
    return;
  }

  // 1. Verify in main isolate.
  checkEnv();

  // 2. Verify in child isolate spawned via Isolate.spawnUri.
  final receivePort = ReceivePort();
  await Isolate.spawnUri(Platform.script, ["--child"], receivePort.sendPort);
  final result = await receivePort.first;
  Expect.equals("OK", result);
}
