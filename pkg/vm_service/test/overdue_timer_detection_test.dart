// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'overdue_timer_detection_lib.dart' as testee_lib;

Future<void> main([List<String> args = const <String>[]]) => IsolateTestHarness(
      'overdue_timer_detection_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final completer = Completer<void>();
      late final StreamSubscription<Event> sub;
      sub = service.onTimerEvent.listen((Event event) async {
        if (event.kind == 'TimerSignificantlyOverdue') {
          final detailsRegex = RegExp(
            r'A timer should have fired (\d+) ms ago, but just fired now.',
          );
          final millisecondsOverdueAsString =
              detailsRegex.firstMatch(event.details!)![1]!;
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
    }).run(
      testeeMain: testee_lib.main,
      pauseOnStart: true,
    );
