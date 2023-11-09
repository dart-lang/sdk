// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Ensure that compute isolate can exit if paused on exit
// BUG=https://github.com/dart-lang/sdk/issues/51164

import 'dart:async';
import 'dart:isolate' as iso;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> _compute() async {
  iso.ReceivePort();
  print('compute is done');
}

void testMain() async {
  await iso.Isolate.run(_compute);
  print('Done');
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    final computeCompleter = Completer<void>();
    final mainCompleter = Completer<void>();

    final computeIsolate = Completer<String>();

    final mainIsolateId = isolateRef.id!;
    print('Main Isolate ID: $mainIsolateId');

    final stream = service.onDebugEvent;
    final subscription = stream.listen((Event event) async {
      final isolateId = event.isolate!.id!;
      print('debug stream event: $event ($isolateId)');
      switch (event.kind) {
        case EventKind.kPauseExit:
          if (isolateId != mainIsolateId) {
            expect(computeCompleter.isCompleted, false);
            computeCompleter.complete();
          } else {
            expect(mainCompleter.isCompleted, false);
            mainCompleter.complete();
          }
          break;
        case EventKind.kPauseStart:
          computeIsolate.complete(isolateId);
      }
    });
    await service.streamListen(EventStreams.kDebug);

    // Resume the main isolate, causing the compute isolate to start.
    await service.resume(mainIsolateId);

    // Wait for the compute isolate to pause on start.
    final computeIsolateId = await computeIsolate.future;
    await service.resume(computeIsolateId);

    // Wait for pause on exit for compute isolate
    await computeCompleter.future;

    // Resume compute isolate paused on exit
    await service.resume(computeIsolateId);

    // Ensure that main exits as well.
    await mainCompleter.future;
    await subscription.cancel();
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'isolate_exit_resume_test.dart',
      pause_on_start: true,
      pause_on_exit: true,
      testeeConcurrent: testMain,
    );
