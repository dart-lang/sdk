// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override

import 'dart:developer' as developer;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'package:logging/logging.dart';

import 'test_helper.dart';

void init() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((logRecord) {
    developer.log(
        sequenceNumber: logRecord.sequenceNumber,
        millisecondsSinceEpoch: logRecord.time.millisecondsSinceEpoch,
        level: logRecord.level.value,
        name: logRecord.loggerName,
        message: logRecord.message,
        zone: null,
        error: logRecord.error,
        stackTrace: logRecord.stackTrace);
  });
}

void run() {
  developer.debugger();
  Logger.root.fine('Hey Buddy!');
  developer.debugger();
  Logger.root.info('YES');
}

var tests = [
  hasStoppedAtBreakpoint,
  resumeIsolateAndAwaitEvent(Isolate.kLoggingStream, (ServiceEvent event) {
    expect(event.kind, equals(ServiceEvent.kLogging));
    expect(event.logRecord['sequenceNumber'], equals(0));
    expect(event.logRecord['message'].valueAsString, equals('Hey Buddy!'));
    expect(event.logRecord['level'], equals(Level.FINE));
    expect(event.logRecord['time'], new isInstanceOf<DateTime>());
  }),
  resumeIsolateAndAwaitEvent(Isolate.kLoggingStream, (ServiceEvent event) {
    expect(event.kind, equals(ServiceEvent.kLogging));
    expect(event.logRecord['sequenceNumber'], equals(1));
    expect(event.logRecord['level'], equals(Level.INFO));
    expect(event.logRecord['message'].valueAsString, equals('YES'));
    expect(event.logRecord['time'], new isInstanceOf<DateTime>());
  }),
];

main(args) => runIsolateTests(args,
                              tests,
                              testeeBefore: init,
                              testeeConcurrent: run);
