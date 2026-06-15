// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'logging_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('logging_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(
          resumeIsolateAndAwaitEvent(EventStreams.kLogging, (event) {
            expect(event.kind, EventKind.kLogging);
            expect(event.logRecord!.sequenceNumber, 0);
            expect(event.logRecord!.message!.valueAsString, 'Hey Buddy!');
            expect(event.logRecord!.level, Level.FINE.value);
            expect(event.logRecord!.time, isNotNull);
          }),
        )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(
          resumeIsolateAndAwaitEvent(EventStreams.kLogging, (event) {
            expect(event.kind, EventKind.kLogging);
            expect(event.logRecord!.sequenceNumber, 1);
            expect(event.logRecord!.message!.valueAsString, 'YES');
            expect(event.logRecord!.level, Level.INFO.value);
            expect(event.logRecord!.time, isNotNull);
          }),
        )
        .run(testeeMain: testee_lib.main);
