// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:expect/expect.dart';

import 'reload_utils.dart';

final N = runningInSimulator ? 2 : math.min(20, Platform.numberOfProcessors);

main() async {
  if (!currentVmSupportsReload) return;

  await withTempDir((String tempDir) async {
    final dills = await generateDills(tempDir, dartTestFile(N));
    final reloader = await launchOn(dills[0] /*, verbose: true*/);

    await reloader.waitUntilStdoutContains('Initial child isolates launched');

    // Let's give the test some time to spawn isolates on the N parallel tracks.
    await Future.delayed(const Duration(milliseconds: 100));

    final reloadResult = await reloader.reload(dills[1]);
    Expect.equals('ReloadReport', reloadResult['type']);
    Expect.equals(true, reloadResult['success']);

    await reloader.waitUntilStdoutContains('All child isolates died normally');

    final int exitCode = await reloader.close();
    Expect.equals(0, exitCode);
  });
}

String dartTestFile(int N) => '''
import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

const int parallel = $N;

@pragma('vm:never-inline')
bool isDone() {
  return false; // @include-in-reload-0
  return true; // @include-in-reload-1
}

Future main() async {
  final done = ReceivePort();
  final results = ReceivePort();
  final errors = ReceivePort();
  for (int parallelTrack = 0; parallelTrack < parallel; ++parallelTrack) {
    const int sequenceNumber = 0;
    final fakeAttachOnExitHandler = ReceivePort();
    await Future.delayed(const Duration(milliseconds: 1));
    final childMessage = ChildMessage(
      parallelTrack,
      sequenceNumber,
      results.sendPort,
      done.sendPort,
      errors.sendPort,
      fakeAttachOnExitHandler.sendPort);
    await Isolate.spawn(
        child, childMessage,
        onExit: done.sendPort,
        onError: errors.sendPort,
        debugName: 'track-\$parallelTrack-\$sequenceNumber');
    fakeAttachOnExitHandler.first.then((dynamic message) {
      (message as SendPort).send(null);
    });
  }
  print('Initial child isolates launched');

  print('Waiting for reload to happen ...');
  while (!isDone()) {
    print(' -> Still waiting ...');
    await Future.delayed(const Duration(milliseconds: 50));
  }
  print('-> reload done');

  final allErrors = [];
  errors.listen((e) {
    print('error: \$e');
    allErrors.add(e);
  });

  print('Waiting for parallel track results ...');
  int childCount = 0;
  final lsi = StreamIterator(results);
  for (int i = 0; i < parallel; ++i) {
    Expect.isTrue(await lsi.moveNext());
    final result = lsi.current as ParallelTrackResult;
    print('Got result: \$result');
    childCount += result.sequenceNumber;
  }
  await lsi.cancel();
  print('-> total number of isolate started: \$childCount');
  print('Waiting for their onDone ...');

  final si = StreamIterator(done);
  for (int i = 0; i < childCount; ++i) {
    Expect.isTrue(await si.moveNext());
  }
  await si.cancel();
  print('All children died');

  errors.close();
  Expect.equals(0, allErrors.length);

  print('All child isolates died normally');
}

void child(ChildMessage message) async {
  // Wait for parent to die before spawning our child to ensure we
  // don't spawn isolates faster than they can die.
  final onParentExit = ReceivePort();
  message.attachParentOnExitListenerPort.send(onParentExit.sendPort);
  await onParentExit.first;

  if (!isDone()) {
    final attachOnExitListener = ReceivePort();
    final childMessage = message.next(attachOnExitListener.sendPort);
    Isolate.spawn(
        child, childMessage,
        onError: message.parallelTrackErrorPort,
        onExit: message.parallelTrackEndPort,
        debugName: 'track-\${message.parallelTrack}-\${message.sequenceNumber}');
    Isolate.current.addOnExitListener((await attachOnExitListener.first) as SendPort);
  } else {
    message.parallelTrackResultPort.send(message.result);
  }
}

class ChildMessage {
  final int parallelTrack;
  final int sequenceNumber;
  final SendPort parallelTrackResultPort;
  final SendPort parallelTrackEndPort;
  final SendPort parallelTrackErrorPort;
  final SendPort attachParentOnExitListenerPort;

  ChildMessage(this.parallelTrack,
               this.sequenceNumber,
               this.parallelTrackResultPort,
               this.parallelTrackEndPort,
               this.parallelTrackErrorPort,
               this.attachParentOnExitListenerPort);

  ChildMessage next(SendPort newAttachParentOnExitListenerPort) {
    return ChildMessage(parallelTrack,
               sequenceNumber + 1,
               parallelTrackResultPort,
               parallelTrackEndPort,
               parallelTrackErrorPort,
               newAttachParentOnExitListenerPort);
  }

  ParallelTrackResult get result {
    return ParallelTrackResult(parallelTrack, sequenceNumber + 1);
  }
}

class ParallelTrackResult {
  final int parallelTrack;
  final int sequenceNumber;
  ParallelTrackResult(this.parallelTrack, this.sequenceNumber);

  String toString() => 'ParallelTrackResult(\$parallelTrack, \$sequenceNumber)';
}
''';
