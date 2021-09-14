// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

worker(SendPort sendPort) {
  final re = RegExp(r'(x+)*y');
  final s = 'x' * 100 + '';
  sendPort.send('worker started');
  print(re.allMatches(s).iterator.moveNext());
}

main() async {
  asyncStart();
  ReceivePort onExit = ReceivePort();
  ReceivePort workerStarted = ReceivePort();
  final isolate = await Isolate.spawn(worker, workerStarted.sendPort,
      onExit: onExit.sendPort, errorsAreFatal: true);
  await workerStarted.first;
  print('worker started, now killing worker');
  isolate.kill(priority: Isolate.immediate);
  await onExit.first;
  print('worker exited');
  asyncEnd();
}
