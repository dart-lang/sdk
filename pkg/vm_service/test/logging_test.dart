// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 32;
const LINE_B = LINE_A + 2;

void init() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((logRecord) {
    log(logRecord.message,
        time: logRecord.time,
        sequenceNumber: logRecord.sequenceNumber,
        level: logRecord.level.value,
        name: logRecord.loggerName,
        zone: null,
        error: logRecord.error,
        stackTrace: logRecord.stackTrace);
  });
}

void run() {
  debugger();
  Logger.root.fine('Hey Buddy!');
  debugger();
  Logger.root.info('YES');
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolateAndAwaitEvent(EventStreams.kLogging, (event) {
    expect(event.kind, EventKind.kLogging);
    expect(event.logRecord!.sequenceNumber, 0);
    expect(event.logRecord!.message!.valueAsString, 'Hey Buddy!');
    expect(event.logRecord!.level, Level.FINE.value);
    expect(event.logRecord!.time, isNotNull);
  }),
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolateAndAwaitEvent(EventStreams.kLogging, (event) {
    expect(event.kind, EventKind.kLogging);
    expect(event.logRecord!.sequenceNumber, 1);
    expect(event.logRecord!.message!.valueAsString, 'YES');
    expect(event.logRecord!.level, Level.INFO.value);
    expect(event.logRecord!.time, isNotNull);
  }),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'logging_test.dart',
      testeeBefore: init,
      testeeConcurrent: run,
    );
