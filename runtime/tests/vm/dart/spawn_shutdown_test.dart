// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-asserts

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

// This test attempts to check that the vm can shutdown cleanly when
// isolates are starting and stopping.
//
// We spawn a set of workers.  Each worker will kill its parent
// worker (if any) and then spawn a child worker.  We start these
// workers in a staggered fashion in an attempt to see a variety of
// isolate states at the time that this program terminates.

trySpawn(Function f, Object o) async {
  try {
    await Isolate.spawn<SendPort>(f, o);
  } catch (e) {
    // Isolate spawning may fail if the program is ending.
    assert(e is IsolateSpawnException);
  }
}

void worker(SendPort parentPort) {
  var port = new RawReceivePort();

  // This worker will exit when it receives any message.
  port.handler = (_) {
    port.close();
  };

  // Send a message to terminate our parent isolate.
  if (parentPort != null) {
    parentPort.send(null);
  }

  // Spawn a child worker.
  trySpawn(worker, port.sendPort);
}

void main() {
  const numWorkers = 50;
  const delay = const Duration(milliseconds: (1000 ~/ numWorkers));
  const exitDelay = const Duration(seconds: 2);

  // Take about a second to spin up our workers in a staggered
  // fashion. We want to maximize the chance that they will be in a
  // variety of states when the vm shuts down.
  print('Starting ${numWorkers} workers...');
  for (int i = 0; i < numWorkers; i++) {
    trySpawn(worker, null);
    sleep(delay);
  }

  // Let them spin for a bit before terminating the program.
  print('Waiting for ${exitDelay} before exit...');
  sleep(exitDelay);
}
