// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--use_compactor
// VMOptions=--use_compactor --force_evacuation

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:expect/expect.dart';

import 'helpers.dart';

void main() async {
  await testFinalizerInOtherIsolateGroupGCBeforeExit();
  await testFinalizerInOtherIsolateGroupGCAfterExit();
  await testFinalizerInOtherIsolateGroupNoGC();

  print('$name: End of test, shutting down.');
}

const name = 'main';

late bool hotReloadBot;

Future<void> testFinalizerInOtherIsolateGroupGCBeforeExit() async {
  final receivePort = ReceivePort();
  final messagesQueue = StreamQueue(receivePort);

  await Isolate.spawnUri(
    Uri.parse('finalizer_isolate_groups_run_gc_helper.dart'),
    ['helper 1'],
    receivePort.sendPort,
  );
  final signalHelperIsolate = await messagesQueue.next as SendPort;

  doGC(name: name);
  await yieldToMessageLoop(name: name);

  signalHelperIsolate.send('Done GCing.');

  final helperCallbacks = await messagesQueue.next as int;
  messagesQueue.cancel();
  print('$name: Helper exited.');
  // Different isolate group, so we don't expect a GC in this isolate to cause
  // collected objects in the helper.
  // Except for in --hot-reload-test-mode, then the GC is triggered.
  hotReloadBot = helperCallbacks == 1;
}

Future<void> testFinalizerInOtherIsolateGroupGCAfterExit() async {
  final receivePort = ReceivePort();
  final messagesQueue = StreamQueue(receivePort);
  await Isolate.spawnUri(
    Uri.parse('finalizer_isolate_groups_run_gc_helper.dart'),
    ['helper 2'],
    receivePort.sendPort,
  );

  final signalHelperIsolate = await messagesQueue.next as SendPort;

  signalHelperIsolate.send('Before GCing.');

  final helperCallbacks = await messagesQueue.next as int;
  messagesQueue.cancel();
  print('$name: Helper exited.');
  Expect.equals(hotReloadBot ? 1 : 0, helperCallbacks);

  doGC(name: name);
  await yieldToMessageLoop(name: name);
}

Future<void> testFinalizerInOtherIsolateGroupNoGC() async {
  final receivePort = ReceivePort();
  final messagesQueue = StreamQueue(receivePort);

  await Isolate.spawnUri(
    Uri.parse('finalizer_isolate_groups_run_gc_helper.dart'),
    ['helper 3'],
    receivePort.sendPort,
  );
  final signalHelperIsolate = await messagesQueue.next as SendPort;

  signalHelperIsolate.send('Before quitting main isolate.');

  final helperCallbacks = await messagesQueue.next as int;
  messagesQueue.cancel();
  print('$name: Helper exited.');
  Expect.equals(hotReloadBot ? 1 : 0, helperCallbacks);
}
