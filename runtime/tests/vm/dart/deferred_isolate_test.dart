// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify deferred library status is per-isolate, not per-isolate-group.

import 'dart:async';
import 'dart:isolate';
import 'package:expect/expect.dart';

import "gc/splay_test.dart" deferred as splay;

worker(SendPort sendPort) {
  Expect.throws(() => splay.main(),
      (e) => e.toString() == "Deferred library splay was not loaded.");
  sendPort.send(true);
}

main() async {
  await splay.loadLibrary();
  splay.main();
  final receivePort = ReceivePort();
  Isolate.spawn(worker, receivePort.sendPort);
  Expect.isTrue(await receivePort.first);
  receivePort.close();
}
