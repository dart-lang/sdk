// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show sleep;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> testeeMain() async {
  final completer = Completer<void>();
  late final Timer t;
  t = Timer(
    const Duration(milliseconds: 100),
    () {
      t.cancel();
      completer.complete();
    },
  );

  // Sleep for 201 ms to force [t] to fire at least 100 ms late. This allows us
  // to expect to receive at least one 'TimerSignificantlyOverdue' event in
  // [tests] below, because a 'TimerSignificantlyOverdue' event should be fired
  // whenever a timer is identified to be at least 100 ms overdue.
  sleep(const Duration(milliseconds: 201));
  await completer.future;
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    late final StreamSubscription<Event> sub;
    sub = service.onTimerEvent.listen((Event event) async {
      if (event.kind == 'TimerSignificantlyOverdue') {
        final detailsRegex = RegExp(
          r'A timer should have fired (\d+) ms ago, but just fired now.',
        );
        final millisecondsOverdueAsString =
            detailsRegex.firstMatch(event.details!)!.group(1)!;
        expect(
          int.parse(millisecondsOverdueAsString),
          greaterThanOrEqualTo(100),
        );
        await sub.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kTimer);

    await service.resume(isolateRef.id!);
    await completer.future;
  },
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'overdue_timer_detection_test.dart',
      testeeConcurrent: testeeMain,
      pauseOnStart: true,
    );
