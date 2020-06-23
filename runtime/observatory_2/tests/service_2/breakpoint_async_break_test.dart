// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:async';

const int LINE = 17;

// Issue: https://github.com/dart-lang/sdk/issues/36622
Future<void> testMain() async {
  for (int i = 0; i < 2; i++) {
    if (i > 0) {
      break; // breakpoint here
    }
    await Future.delayed(Duration(seconds: 1));
  }
}

var tests = <IsolateTest>[
  hasPausedAtStart,

  // Test future breakpoints.
  (Isolate isolate) async {
    var rootLib = isolate.rootLibrary;
    await rootLib.load();
    var script = rootLib.scripts[0];

    // Future breakpoint.
    var futureBpt = await isolate.addBreakpoint(script, LINE);
    expect(futureBpt.number, 1);
    expect(futureBpt.resolved, isFalse);
    expect(await futureBpt.location.getLine(), LINE);
    expect(await futureBpt.location.getColumn(), null);

    var stream = await isolate.vm.getEventStream(VM.kDebugStream);
    Completer completer = new Completer();
    var subscription;
    var resolvedCount = 0;
    subscription = stream.listen((ServiceEvent event) async {
      if (event.kind == ServiceEvent.kBreakpointResolved) {
        resolvedCount++;
      }
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        subscription.cancel();
        completer.complete();
      }
    });
    await isolate.resume();
    await hasStoppedAtBreakpoint(isolate);

    // After resolution the breakpoints have assigned line & column.
    expect(resolvedCount, 1);
    expect(futureBpt.resolved, isTrue);
    expect(await futureBpt.location.getLine(), LINE);
    expect(await futureBpt.location.getColumn(), 7);

    // Remove the breakpoints.
    expect((await isolate.removeBreakpoint(futureBpt)).type, 'Success');
  },
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_start: true);
