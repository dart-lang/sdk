// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show sleep;

import 'package:dds_service_extensions/dds_service_extensions.dart';
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
    service.onTimerEvent.listen((event) async {
      expect(event.kind, 'TimerSignificantlyOverdue');

      await service.streamCancel(EventStreams.kTimer);
      completer.complete();
    });
    await service.streamListen(EventStreams.kTimer);

    resumeIsolate(service, isolateRef);
    await completer.future;
  },
  (VmService service, _) async {
    // Confirm that all events in the history buffer get sent on a stream
    // returned by [service.onTimerEventWithHistory].
    final completer = Completer<void>();
    late final StreamSubscription subscription;
    subscription = service.onTimerEventWithHistory.listen((event) async {
      expect(event.kind, 'TimerSignificantlyOverdue');

      await subscription.cancel();
      completer.complete();
    });
    await service.streamListen(EventStreams.kTimer);
    await completer.future;
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'timer_event_history_test.dart',
      testeeConcurrent: testeeMain,
      pauseOnStart: true,
      pauseOnExit: true,
    );
