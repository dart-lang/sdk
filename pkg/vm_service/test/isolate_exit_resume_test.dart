// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Ensure that compute isolate can exit if paused on exit
// BUG=https://github.com/dart-lang/sdk/issues/51164

import 'dart:async';
import 'dart:isolate' as iso;

import 'package:vm_service/vm_service.dart';

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
  (VmService service, IsolateRef isolateRef) async {
    // await service.setIsolatePauseMode(isolateRef.id!, shouldPauseOnExit: true);
    // expect(await shouldPauseOnExit(service, isolateRef), true);
    final computeCompleter = Completer<void>();
    final mainCompleter = Completer<void>();

    final mainIsolate = Completer<String>();
    final computeIsolate = Completer<String>();

    final stream = service.onDebugEvent;
    final subscription = stream.listen((Event event) {
      print('debug stream event: $event');
      switch (event.kind) {
        case EventKind.kPauseExit:
          if (!computeCompleter.isCompleted) {
            computeCompleter.complete();
          } else {
            mainCompleter.complete();
          }
          break;
        case EventKind.kPauseStart:
          if (!mainIsolate.isCompleted) {
            mainIsolate.complete(event.isolate!.id!);
          } else {
            computeIsolate.complete(event.isolate!.id!);
          }
          service.resume(event.isolate!.id!);
      }
    });
    await service.streamListen(EventStreams.kDebug);

    // Wait for pause on exit for compute isolate
    await computeCompleter.future;
    // Resume compute isolate paused on exit
    await service.resume(await computeIsolate.future);
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
