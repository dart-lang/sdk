// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

Future testMain() async {
  // Trigger the posting of 9 logging events.
  for (int i = 1; i <= 9; ++i) {
    log(i.toString());
    // Wait between posting events to make it more likely for the test below to
    // exercise the logic that makes [service.onLoggingEventWithHistory] return
    // both historical and future events.
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

final tests = <IsolateTest>[
  (VmService service, _) async {
    // Confirm that all events in the history buffer get sent on a stream
    // returned by [service.onLoggingEventWithHistory], and that all events
    // posted after a listener has been added to the returned stream get sent to
    // that listener.
    final completer = Completer<void>();
    int i = 1;
    late final StreamSubscription subscription;
    subscription = service.onLoggingEventWithHistory.listen((event) async {
      expect(event.kind, 'Logging');
      expect(event.logRecord!.message!.valueAsString!, i.toString());
      i++;

      if (i == 10) {
        await subscription.cancel();
        completer.complete();
      } else if (i > 10) {
        fail('Too many "Logging" events encountered');
      }
    });
    await service.streamListen(EventStreams.kLogging);
    await completer.future;
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'logging_event_history_test.dart',
      testeeConcurrent: testMain,
      pauseOnExit: true,
    );
