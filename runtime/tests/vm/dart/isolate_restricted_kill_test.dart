// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies that restricted isolate can't be terminated.
//
import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

main() async {
  asyncStart();

  int receivedCounter = -1;
  final rp = RawReceivePort((value) {
    receivedCounter = value;
  });
  final rpExit = ReceivePort();

  final isolate = await Isolate.spawn(
    (sendPort) async {
      int counter = 0;
      while (true) {
        sendPort.send(counter++);
        await Future.delayed(Duration(milliseconds: 100));
      }
    },
    rp.sendPort,
    onExit: rpExit.sendPort,
  );

  // Wait for the isolate to start.
  while (receivedCounter < 0) {
    await Future.delayed(Duration(milliseconds: 100));
  }

  // Create restricted isolate, the one that can't be terminated.
  final restricted = Isolate(isolate.controlPort);
  restricted.kill();
  final before_kill = receivedCounter;
  // Wait couple cycles to ensure isolate is still alive.
  while (receivedCounter < before_kill + 2) {
    await Future.delayed(Duration(milliseconds: 100));
  }

  // Now kill the original isolate and wait for it to exit.
  isolate.kill();
  await rpExit.first;

  rp.close();
  asyncEnd();
}
