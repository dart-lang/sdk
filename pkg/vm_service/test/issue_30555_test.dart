// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'issue_30555_lib.dart' as testee_lib;

late final IsolateRef firstIsolate;
late final IsolateRef secondIsolate;

void main([List<String> args = const <String>[]]) => IsolateTestHarness(
      'issue_30555_lib.dart',
      args,
    ).hasPausedAtStart().addCustomTestWithParser(
      (
        VmService service,
        IsolateRef isolateRef,
        TestScriptParser parser,
      ) async {
        firstIsolate = isolateRef;

        // Capture the second isolate when it spawns.
        final completer = Completer<void>();
        late final StreamSubscription sub;
        sub = service.onDebugEvent.listen((event) async {
          if (event.kind == EventKind.kPauseStart) {
            secondIsolate = event.isolate!;
            await sub.cancel();
            await service.streamCancel(EventStreams.kDebug);
            completer.complete();
          }
        });
        await service.streamListen(EventStreams.kDebug);

        // Resume and wait for the second isolate to spawn.
        await resumeIsolate(service, firstIsolate);
        await completer.future;

        // Resume the second isolate.
        await resumeIsolate(service, secondIsolate);

        final lineB = parser.lineForTag('LINE_B');
        final lineC = parser.lineForTag('LINE_C');
        final lineA = parser.lineForTag('LINE_A');
        final lineD = parser.lineForTag('LINE_D');

        // First isolate should pause at LINE_B.
        await hasStoppedAtBreakpoint(service, firstIsolate);
        await stoppedAtLine(lineB)(service, firstIsolate);
        await resumeIsolate(service, firstIsolate);

        // First isolate should pause at LINE_C and second isolate should pause
        // at LINE_A.
        //
        // Note: the ordering of the following four checks doesn't matter as
        // `hasStoppedAtBreakpoint` and `stoppedAtLine` both handle breakpoint
        // events received on the debug stream while also checking whether an
        // isolate already hit the breakpoint. However, interleaving these using
        // Future.wait() may cause the debug stream to be cancelled after one of
        // the checks completes and the other check is waiting on an event, causing
        // the test to hang.
        await hasStoppedAtBreakpoint(service, firstIsolate);
        await stoppedAtLine(lineC)(service, firstIsolate);
        await hasStoppedAtBreakpoint(service, secondIsolate);
        await stoppedAtLine(lineA)(service, secondIsolate);

        // Resume the second isolate.
        await resumeIsolate(service, secondIsolate);

        // The second isolate should exit due to an exception.
        await hasStoppedAtExit(service, secondIsolate);

        // Resume the first isolate.
        await resumeIsolate(service, firstIsolate);

        // The first isolate should pause at LINE_D.
        await hasStoppedAtBreakpoint(service, firstIsolate);
        await stoppedAtLine(lineD)(service, firstIsolate);
      },
    ).run(
      testeeMain: testee_lib.main,
      pauseOnStart: true,
      pauseOnExit: true,
    );
